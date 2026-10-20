# frozen_string_literal: true

module Mcp
  # Declares the assistant-facing tool schemas and permission boundaries.
  module Tools
    FLIGHT_ID = {type: "string", description: "Flight UUID returned by list_flights or create_flight."}.freeze
    DATE = {type: "string", description: "Flight date in YYYY-MM-DD format.", pattern: "^\\d{4}-\\d{2}-\\d{2}$"}.freeze
    DESCRIPTION = {type: %w[string null], maxLength: 200}.freeze

    # @return [Array<Class<MCP::Tool>>] Tools whose execution context is supplied per request.
    def self.build
      [
          tool("list_flights", "List your flights, newest first, with passenger counts and invitation links.",
               {page: {type: "integer", minimum: 1}, limit: {type: "integer", minimum: 1, maximum: 100}}, [], read: true),
          tool("get_flight", "Read one of your flights, its passenger and cargo weights, and weight totals. Units are explicit; these are not aircraft balance calculations.",
               {flight_id: FLIGHT_ID}, %w[flight_id], read: true),
          tool("create_flight", "Create a flight and obtain its passenger invitation link. Does not send invitations.",
               {date: DATE, description: DESCRIPTION}, %w[date]),
          tool("update_flight", "Update the date or description of one of your flights.",
               {flight_id: FLIGHT_ID, date: DATE, description: DESCRIPTION}, %w[flight_id], destructive: true),
          tool("delete_flight", "Permanently delete one of your flights and all its passenger and cargo loads.",
               {flight_id: FLIGHT_ID}, %w[flight_id], destructive: true),
          tool("upsert_load", "Add or replace a load matched by its name-derived slug. Supply both weights and an explicit unit. Cargo uses weight=0 and bags_weight for its weight.",
               {flight_id: FLIGHT_ID, name: {type: "string", minLength: 1, maxLength: 100},
                weight: {type: "number", minimum: 0}, bags_weight: {type: "number", minimum: 0}, unit: {type: "string", enum: %w[lb kg]}},
               %w[flight_id name weight bags_weight unit], destructive: true),
          tool("delete_load", "Permanently remove a passenger or cargo load from one of your flights.",
               {flight_id: FLIGHT_ID, slug: {type: "string"}}, %w[flight_id slug], destructive: true)
      ]
    end

    def self.tool(name, description, properties, required, read: false, destructive: false)
      MCP::Tool.define(name: name, description: description,
                       input_schema: {type: "object", properties: properties, required: required, additionalProperties: false},
                       annotations: {read_only_hint: read, destructive_hint: destructive, open_world_hint: false}) do |server_context:, **arguments|
        Tools.observe(name) do
          unless server_context.fetch(:scopes).include?(Tools.required_scope(self))
            next Tools.response({error: "insufficient_scope", message: "Reconnect with permission to manage flights."}, error: true)
          end

          result = Operations.new(server_context.fetch(:pilot)).public_send(name, **arguments)
          Tools.response(result)
        rescue ActiveRecord::RecordNotFound
          Tools.response({error: "not_found", message: "Flight or load not found."}, error: true)
        rescue ActiveRecord::RecordInvalid => e
          Tools.response({error: "validation_failed", fields: e.record.errors.to_hash}, error: true)
        rescue ActiveRecord::RecordNotUnique, ActiveModel::StrictValidationFailed
          Tools.response({error: "conflict", message: "The load changed concurrently. Read the flight before retrying."}, error: true)
        rescue ArgumentError => e
          Tools.response({error: "invalid_arguments", message: e.message}, error: true)
        end
      end
    end
    private_class_method :tool

    # @param tool [Class<MCP::Tool>] A tool from {build}.
    # @return [String] The scope a tool requires, derived from its read-only annotation.
    def self.required_scope(tool) = tool.annotations_value.read_only_hint ? Settings::READ_SCOPE : Settings::WRITE_SCOPE

    # Records tool outcomes and duration without passenger data or arguments.
    # @return [MCP::Tool::Response] The tool's result.
    def self.observe(name)
      started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      result = yield
    ensure
      duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000
      Rails.logger.info({event: "mcp.tool", tool: name, outcome: (result && !result.error?) ? "ok" : "error", duration_ms: duration.round}.to_json)
    end

    # @return [MCP::Tool::Response] Structured data with a text representation for older hosts.
    def self.response(data, error: false)
      MCP::Tool::Response.new([{type: "text", text: JSON.generate(data)}], error: error, structured_content: data)
    end
  end
end
