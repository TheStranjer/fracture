# frozen_string_literal: true

module Fracture
  module Tools
    class RemoveRole < MCP::Tool
      tool_name 'remove_role'
      description 'Removes a role from a Discord member within a specific guild'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild'
          },
          member_id: {
            type: 'string',
            description: 'The ID of the member to remove the role from'
          },
          role_id: {
            type: 'string',
            description: 'The ID of the role to remove'
          }
        },
        required: %w[guild_id member_id role_id]
      )

      class << self
        attr_accessor :discord_client

        def build(discord_client)
          self.discord_client = discord_client
          self
        end

        def call(guild_id:, member_id:, role_id:)
          server = discord_client.server(guild_id.to_i)
          return error_response("Guild not found: #{guild_id}") unless server

          perform_remove(server, member_id, role_id)
        end

        private

        def perform_remove(server, member_id, role_id)
          member = server.member(member_id.to_i)
          return error_response("Member not found: #{member_id}") unless member

          role = find_role(server, role_id)
          return error_response("Role not found: #{role_id}") unless role

          member.remove_role(role)
          success_response
        end

        def find_role(server, role_id)
          server.roles.find { |r| r.id == role_id.to_i }
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
