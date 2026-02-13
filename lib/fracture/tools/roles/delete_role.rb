# frozen_string_literal: true

module Fracture
  module Tools
    class DeleteRole < MCP::Tool
      tool_name 'delete_role'
      description 'Deletes a role from a Discord guild'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild'
          },
          role_id: {
            type: 'string',
            description: 'The ID of the role to delete'
          }
        },
        required: %w[guild_id role_id]
      )

      class << self
        attr_accessor :discord_client

        def build(discord_client)
          self.discord_client = discord_client
          self
        end

        def call(guild_id:, role_id:)
          server = discord_client.server(guild_id.to_i)
          return error_response("Guild not found: #{guild_id}") unless server

          perform_delete(server, role_id)
        end

        private

        def perform_delete(server, role_id)
          role = server.roles.find { |r| r.id == role_id.to_i }
          return error_response("Role not found: #{role_id}") unless role

          role.delete
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
