# frozen_string_literal: true

module Fracture
  module Tools
    class RenameChannel < MCP::Tool
      tool_name 'rename_channel'
      description 'Renames a channel in a Discord guild'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild'
          },
          channel_id: {
            type: 'string',
            description: 'The ID of the channel to rename'
          },
          name: {
            type: 'string',
            description: 'The new name for the channel'
          }
        },
        required: %w[guild_id channel_id name]
      )

      class << self
        attr_accessor :discord_client

        def build(discord_client)
          self.discord_client = discord_client
          self
        end

        def call(guild_id:, channel_id:, name:)
          server = discord_client.server(guild_id.to_i)
          return error_response("Guild not found: #{guild_id}") unless server

          perform_rename(server, channel_id, name)
        end

        private

        def perform_rename(server, channel_id, name)
          channel = server.channels.find { |c| c.id == channel_id.to_i }
          return error_response("Channel not found: #{channel_id}") unless channel

          channel.name = name
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
