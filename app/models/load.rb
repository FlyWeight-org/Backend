# frozen_string_literal: true

# A Load is a passenger or cargo on a {Flight}. A passenger has a `weight` > 0
# and a `bags_weight` ≥ 0. Cargo has a `weight` of 0 and a `bags_weight` > 0.
#
# Each Load has a `slug` that is automatically generated from its `name`. Load
# slugs are unique per Flight.
#
# Associations
# ------------
#
# |          |                                    |
# |:---------|:-----------------------------------|
# | `flight` | The {Flight} this Load belongs to. |
#
# Properties
# ----------
#
# |                       |                                                                                 |
# |:----------------------|:--------------------------------------------------------------------------------|
# | `name`                | The name of the passenger or a description of the cargo.                        |
# | `slug`                | The unique identifier derived from the `name`.                                  |
# | `weight`              | The weight of the passenger (0 for cargo).                                      |
# | `bags_weight`         | The weight of the passenger's bags (if any), or the weight of the cargo.        |
# | `covid19_vaccination` | `true` if the passenger is up-to-date on COVID-19 vaccinations (n/a for cargo). |

class Load < ApplicationRecord
  belongs_to :flight

  scope :passengers, -> { where arel_table[:weight].gt(0) }
  scope :cargo, -> { where weight: 0 }

  validates :name,
            presence: true,
            length:   {maximum: 100}

  validates :slug,
            # presence:   true,
            uniqueness: {scope: :flight_id},
            strict:     true

  validates :weight,
            presence:     true,
            numericality: {only_integer: true, greater_than_or_equal_to: 0}

  validates :bags_weight,
            presence:     true,
            numericality: {only_integer: true, greater_than_or_equal_to: 0}

  validate :total_weight_greater_than_zero

  before_validation :set_slug
  after_commit { LoadsChannel.broadcast_to flight, LoadsChannel::Coder.encode(self) }

  # @private
  def to_param = slug

  # @return [true, false] Whether this Load is a passenger.

  def passenger? = weight.positive?

  # @return [true, false] Whether this load is cargo.

  def cargo? = weight.zero? && bags_weight.positive?

  private

  def set_slug
    self.slug = name.parameterize if name.present?
  end

  def total_weight_greater_than_zero
    return unless weight.zero? && bags_weight.zero?

    errors.add :weight, :greater_than, count: 0
    errors.add :bags_weight, :greater_than, count: 0
  end
end
