# frozen_string_literal: true

module Fracture
  module Tools
    class DefineOverwrite < MCP::Tool
      tool_name 'define_overwrite'
      description 'Defines a permission overwrite for a role or user on a channel or category'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild'
          },
          type: {
            type: 'string',
            enum: %w[role channel category user],
            description: 'The type of the target: role, channel, category, or user'
          },
          id: {
            type: 'string',
            description: 'The ID of the target (role, channel, category, or user)'
          },
          target_id: {
            type: 'string',
            description: 'The complementary target ID (channel/category for role/user, or vice versa)'
          },
          allowed: {
            type: 'array',
            items: { type: 'string' },
            description: 'Array of permission names to allow'
          },
          denied: {
            type: 'array',
            items: { type: 'string' },
            description: 'Array of permission names to deny'
          },
          reason: {
            type: 'string',
            description: 'The reason for the overwrite'
          }
        },
        required: %w[guild_id type id target_id allowed denied reason]
      )

      class << self
        attr_accessor :discord_client

        def build(discord_client)
          self.discord_client = discord_client
          self
        end

        def call(guild_id:, type:, id:, target_id:, allowed:, denied:, reason:) # rubocop:disable Metrics/ParameterLists
          server = discord_client.server(guild_id.to_i)
          return error_response("Guild not found: #{guild_id}") unless server

          apply_overwrite(server, type, id, target_id, build_permissions(allowed, denied), reason)
        end

        private

        def build_permissions(allowed, denied)
          {
            allow: Discordrb::Permissions.new(Permissions.array_to_bits(allowed)),
            deny: Discordrb::Permissions.new(Permissions.array_to_bits(denied))
          }
        end

        def apply_overwrite(server, type, id, target_id, perms, reason) # rubocop:disable Metrics/ParameterLists
          channel, overwrite_target = resolve_targets(server, type, id, target_id)
          return error_response('Channel or category not found') unless channel
          return error_response('Overwrite target not found') unless overwrite_target

          channel.define_overwrite(overwrite_target, perms[:allow], perms[:deny], reason: reason)
          success_response
        end

        def resolve_targets(server, type, id, target_id)
          case type
          when 'role'
            [find_channel(server, target_id), find_role(server, id)]
          when 'user'
            [find_channel(server, target_id), server.member(id.to_i)]
          when 'channel', 'category'
            [find_channel(server, id), find_role_or_member(server, target_id)]
          end
        end

        def find_channel(server, channel_id)
          server.channels.find { |c| c.id == channel_id.to_i }
        end

        def find_role(server, role_id)
          server.roles.find { |r| r.id == role_id.to_i }
        end

        def find_role_or_member(server, target_id)
          find_role(server, target_id) || server.member(target_id.to_i)
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
