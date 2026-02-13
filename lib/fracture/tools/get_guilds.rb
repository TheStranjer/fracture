# frozen_string_literal: true

module Fracture
  module Tools
    class GetGuilds < MCP::Tool
      tool_name 'get_guilds'
      description 'Lists all Discord guilds (servers) the bot is a member of'
      input_schema(properties: {})

      class << self
        attr_accessor :discord_client

        def build(discord_client)
          self.discord_client = discord_client
          self
        end

        def call(**_kwargs)
          guilds = discord_client.servers.map do |id, server|
            { id: id.to_s, name: server.name }
          end

          MCP::Tool::Response.new([{ type: 'text', text: guilds.to_json }])
        end
      end
    end
  end
end
