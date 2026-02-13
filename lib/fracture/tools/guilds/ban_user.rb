# frozen_string_literal: true

module Fracture
  module Tools
    class BanUser < MCP::Tool
      tool_name 'ban_user'
      description 'Bans a user from a Discord guild'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild'
          },
          user_id: {
            type: 'string',
            description: 'The ID of the user to ban'
          },
          reason: {
            type: 'string',
            description: 'The reason for the ban'
          }
        },
        required: %w[guild_id user_id reason]
      )

      class << self
        attr_accessor :discord_client

        def build(discord_client)
          self.discord_client = discord_client
          self
        end

        def call(guild_id:, user_id:, reason:)
          server = discord_client.server(guild_id.to_i)
          return error_response("Guild not found: #{guild_id}") unless server

          server.ban(user_id.to_i, reason: reason)
          success_response
        end

        private

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
