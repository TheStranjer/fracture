# frozen_string_literal: true

module Fracture
  module Tools
    class GetMember < MCP::Tool
      tool_name 'get_member'
      description 'Gets detailed information about a Discord member by their user ID within a specific guild'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild the member belongs to'
          },
          member_id: {
            type: 'string',
            description: 'The ID of the member to look up'
          }
        },
        required: %w[guild_id member_id]
      )

      class << self
        attr_accessor :discord_client

        def build(discord_client)
          self.discord_client = discord_client
          self
        end

        def call(guild_id:, member_id:)
          server = discord_client.server(guild_id.to_i)
          return error_response("Guild not found: #{guild_id}") unless server

          fetch_member_data(server, member_id)
        end

        private

        def fetch_member_data(server, member_id)
          member = server.member(member_id.to_i)
          return error_response("Member not found: #{member_id}") unless member

          MCP::Tool::Response.new([{ type: 'text', text: build_member_data(member).to_json }])
        end

        def error_response(message)
          MCP::Tool::Response.new([{ type: 'text', text: { error: message }.to_json }])
        end

        def build_member_data(member)
          {
            **identity_data(member), **status_data(member), **activity_data(member),
            **colour_data(member), **role_data(member), **voice_data(member)
          }.compact
        end

        def identity_data(member)
          {
            boosting_since: member.boosting_since&.iso8601,
            joined_at: member.joined_at&.iso8601,
            display_name: member.display_name,
            user_name: member.username,
            avatar_url: member.avatar_url
          }
        end

        def status_data(member)
          {
            status: member.status&.to_s,
            owner: (true if member.owner?)
          }
        end

        def activity_data(member)
          {
            game: member.game&.name,
            stream_type: member.game&.type,
            stream_url: member.game&.url
          }
        end

        def colour_data(member)
          {
            colour: colour_value(member),
            colour_role: member.colour_role&.id&.to_s
          }
        end

        def role_data(member)
          {
            highest_role: member.highest_role&.id&.to_s,
            hoist_role: member.hoist_role&.id&.to_s
          }
        end

        def voice_data(member)
          {
            deaf: member.deaf,
            muted: member.mute,
            voice_channel: member.voice_channel&.id&.to_s
          }
        end

        def colour_value(member)
          return unless member.colour_role

          member.colour&.combined
        end
      end
    end
  end
end
