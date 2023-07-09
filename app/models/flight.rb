# frozen_string_literal: true

# A Flight is created by a Pilot representing a proposed flight. Each passenger
# can then add their weight as {Load}s for that flight. Loads also represent
# cargo, which can be added by the pilot.
#
# Associations
# ------------
#
# |         |                                               |
# |:--------|:----------------------------------------------|
# | `pilot` | The {Pilot} that created this Flight.         |
# | `loads` | The {Load}s created by pilots and passengers. |
#
# Properties
# ----------
#
# |               |                                                                                                                     |
# |:--------------|:--------------------------------------------------------------------------------------------------------------------|
# | `date`        | The proposed date for the flight.                                                                                   |
# | `description` | A description of the flight, written by the pilot, to help passengers understand which flight is being referred to. |

class Flight < ApplicationRecord
  belongs_to :pilot

  has_many :loads, dependent: :delete_all do
    # Finds a Load whose `slug` matches that derived from `name`, or initializes
    # a new Load if none exists. Initializes a new (invalid) Load if `name` is
    # empty or invalid.
    #
    # @param [String] name The name for the new or existing Load.
    # @return [Load] An existing or newly-initialized Load.

    def with_name(name)
      if name.present?
        where(slug: name.parameterize).first_or_initialize
      else
        build
      end
    end
  end

  # rubocop:disable Rails/HasManyOrHasOneDependent,Rails/InverseOf
  has_many :passengers, -> { passengers }, class_name: "Load"
  has_many :cargo, -> { cargo }, class_name: "Load"
  # rubocop:enable Rails/HasManyOrHasOneDependent,Rails/InverseOf

  scope :with_passenger_count, -> do
    select("flights.*, COUNT(loads.id) AS passenger_count").
        left_outer_joins(:passengers).
        group("flights.id")
  end

  validates :uuid,
            presence: true

  validates :description,
            length:    {maximum: 200},
            allow_nil: true

  validates :date,
            presence: true

  before_validation :set_uuid
  after_commit { FlightsChannel.broadcast_to pilot, FlightsChannel::Coder.encode(self) }

  after_create :schedule_purge

  # @private
  def to_param = uuid

  # @return [Integer] The number of passengers (Loads with `weight` > 0).

  def passenger_count = read_attribute(:passenger_count) || passengers.count

  private

  def set_uuid
    self.uuid ||= SecureRandom.uuid
  end

  def schedule_purge
    PurgeFlightJob.set(wait_until: date.to_time + 1.week).perform_later(self)
  end
end
