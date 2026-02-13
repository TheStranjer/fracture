# frozen_string_literal: true

module Fracture
  module Tools
    class GetGuildMembers < MCP::Tool
      tool_name 'get_guild_members'
      description 'Lists all members of a guild. Reserved for large servers with more than 100 members.'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild to list members for'
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
          return not_found_response(guild_id) unless server

          members = server.members.map { |member| member_data(member) }
          MCP::Tool::Response.new([{ type: 'text', text: members.to_json }])
        end

        private

        def not_found_response(guild_id)
          MCP::Tool::Response.new([{ type: 'text', text: { error: "Guild not found: #{guild_id}" }.to_json }])
        end

        def member_data(member)
          { id: member.id.to_s, username: member.username, display_name: member.display_name }
        end
      end
    end
  end
end
