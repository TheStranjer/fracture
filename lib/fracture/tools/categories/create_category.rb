# frozen_string_literal: true

module Fracture
  module Tools
    class CreateCategory < MCP::Tool
      tool_name 'create_category'
      description 'Creates a new category in a Discord guild'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild'
          },
          name: {
            type: 'string',
            description: 'The name of the category'
          },
          position: {
            type: 'integer',
            description: 'The position of the category'
          }
        },
        required: %w[guild_id name position]
      )

      class << self
        attr_accessor :discord_client

        def build(discord_client)
          self.discord_client = discord_client
          self
        end

        def call(guild_id:, name:, position:)
          server = discord_client.server(guild_id.to_i)
          return error_response("Guild not found: #{guild_id}") unless server

          category = server.create_channel(name, 4, position: position)
          MCP::Tool::Response.new([{ type: 'text', text: { success: true, category_id: category.id.to_s }.to_json }])
        end

        private

        def error_response(message)
          MCP::Tool::Response.new([{ type: 'text', text: { error: message }.to_json }])
        end
      end
    end
  end
end
