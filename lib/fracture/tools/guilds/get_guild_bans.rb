# frozen_string_literal: true

module Fracture
  module Tools
    class GetGuildBans < MCP::Tool
      tool_name 'get_guild_bans'
      description 'Lists all bans for a Discord guild'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild to list bans for'
          }
        },
        required: ['guild_id']
      )

      class << self
        attr_accessor :discord_client

        def build(discord_client)
          self.discord_client = discord_client
          self
        end

        def call(guild_id:)
          server = discord_client.server(guild_id.to_i)
          return error_response("Guild not found: #{guild_id}") unless server

          bans = server.bans.map { |ban| ban_data(ban) }
          MCP::Tool::Response.new([{ type: 'text', text: bans.to_json }])
        end

        private

        def error_response(message)
          MCP::Tool::Response.new([{ type: 'text', text: { error: message }.to_json }])
        end

        def ban_data(ban)
          { user_id: ban.user.id.to_s, reason: ban.reason }
        end
      end
    end
  end
end
