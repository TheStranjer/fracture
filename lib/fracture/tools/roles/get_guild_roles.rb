# frozen_string_literal: true

module Fracture
  module Tools
    class GetGuildRoles < MCP::Tool
      tool_name 'get_guild_roles'
      description 'Gets all roles for a Discord guild, including decoded permissions'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild'
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

          roles = server.roles.map { |role| build_role_data(role) }
          MCP::Tool::Response.new([{ type: 'text', text: roles.to_json }])
        end

        private

        def build_role_data(role)
          {
            id: role.id.to_s,
            name: role.name,
            colour: role.colour.combined,
            hoist: role.hoist,
            **role_flags(role),
            permissions: Permissions.bits_to_array(role.permissions.bits)
          }
        end

        def role_flags(role)
          { managed: role.managed, mentionable: role.mentionable }
        end

        def error_response(message)
          MCP::Tool::Response.new([{ type: 'text', text: { error: message }.to_json }])
        end
      end
    end
  end
end
