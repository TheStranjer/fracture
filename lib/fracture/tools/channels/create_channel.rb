# frozen_string_literal: true

module Fracture
  module Tools
    class CreateChannel < MCP::Tool
      tool_name 'create_channel'
      description 'Creates a new text channel in a Discord guild, optionally under a category'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild'
          },
          name: {
            type: 'string',
            description: 'The name of the channel'
          },
          category_id: {
            type: 'string',
            description: 'The ID of the parent category (optional)'
          }
        },
        required: %w[guild_id name]
      )

      class << self
        attr_accessor :discord_client

        def build(discord_client)
          self.discord_client = discord_client
          self
        end

        def call(guild_id:, name:, category_id: nil)
          server = discord_client.server(guild_id.to_i)
          return error_response("Guild not found: #{guild_id}") unless server

          channel = create_server_channel(server, name, category_id)
          MCP::Tool::Response.new([{ type: 'text', text: { success: true, channel_id: channel.id.to_s }.to_json }])
        end

        private

        def create_server_channel(server, name, category_id)
          opts = {}
          opts[:parent] = category_id.to_i if category_id
          server.create_channel(name, 0, **opts)
        end

        def error_response(message)
          MCP::Tool::Response.new([{ type: 'text', text: { error: message }.to_json }])
        end
      end
    end
  end
end
