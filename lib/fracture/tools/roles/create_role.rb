# frozen_string_literal: true

module Fracture
  module Tools
    class CreateRole < MCP::Tool
      tool_name 'create_role'
      description 'Creates a new role in a Discord guild'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild'
          },
          name: {
            type: 'string',
            description: 'The name of the role'
          },
          colour: {
            type: 'integer',
            description: 'RGB colour value for the role'
          },
          hoist: {
            type: 'boolean',
            description: 'Whether the role should be displayed separately'
          },
          mentionable: {
            type: 'boolean',
            description: 'Whether the role can be mentioned'
          },
          permissions: {
            type: 'array',
            items: { type: 'string' },
            description: 'Array of permission names (e.g. ["send_messages", "read_messages"])'
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

        def call(guild_id:, name:, **opts)
          server = discord_client.server(guild_id.to_i)
          return error_response("Guild not found: #{guild_id}") unless server

          role = create_server_role(server, name, opts)
          MCP::Tool::Response.new([{ type: 'text', text: { success: true, role_id: role.id.to_s }.to_json }])
        end

        private

        def create_server_role(server, name, opts)
          server.create_role(
            name: name,
            colour: Discordrb::ColourRGB.new(opts.fetch(:colour, 0)),
            hoist: opts.fetch(:hoist, false),
            mentionable: opts.fetch(:mentionable, false),
            permissions: Discordrb::Permissions.new(Permissions.array_to_bits(opts.fetch(:permissions, [])))
          )
        end

        def error_response(message)
          MCP::Tool::Response.new([{ type: 'text', text: { error: message }.to_json }])
        end
      end
    end
  end
end
