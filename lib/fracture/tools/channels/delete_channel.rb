# frozen_string_literal: true

module Fracture
  module Tools
    class DeleteChannel < MCP::Tool
      tool_name 'delete_channel'
      description 'Deletes a channel from a Discord guild'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild'
          },
          channel_id: {
            type: 'string',
            description: 'The ID of the channel to delete'
          }
        },
        required: %w[guild_id channel_id]
      )

      class << self
        attr_accessor :discord_client

        def build(discord_client)
          self.discord_client = discord_client
          self
        end

        def call(guild_id:, channel_id:)
          server = discord_client.server(guild_id.to_i)
          return error_response("Guild not found: #{guild_id}") unless server

          perform_delete(server, channel_id)
        end

        private

        def perform_delete(server, channel_id)
          channel = server.channels.find { |c| c.id == channel_id.to_i }
          return error_response("Channel not found: #{channel_id}") unless channel

          channel.delete
          success_response
        end

        def error_response(message)
          MCP::Tool::Response.new([{ type: 'text', text: { error: message }.to_json }])
        end

        def success_response
          MCP::Tool::Response.new([{ type: 'text', text: { success: true }.to_json }])
        end
      end
    end
  end
end
