# frozen_string_literal: true

module Fracture
  module Tools
    class GetGuild < MCP::Tool
      tool_name 'get_guild'
      description 'Gets detailed information about a specific Discord guild (server) by ID'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild to look up'
          }
        },
        required: ['guild_id']
      )

      MEMBER_DETAIL_THRESHOLD = 100

      class << self
        attr_accessor :discord_client

        def build(discord_client)
          self.discord_client = discord_client
          self
        end

        def call(guild_id:)
          server = discord_client.server(guild_id.to_i)
          return not_found_response(guild_id) unless server

          MCP::Tool::Response.new([{ type: 'text', text: build_guild_data(server).to_json }])
        end

        private

        def not_found_response(guild_id)
          MCP::Tool::Response.new([{ type: 'text', text: { error: "Guild not found: #{guild_id}" }.to_json }])
        end

        def build_guild_data(server)
          {
            id: server.id.to_s,
            name: server.name,
            region_id: server.region_id,
            categories: build_categories(server),
            channels: build_channels(server),
            members: build_members(server)
          }
        end

        def build_categories(server)
          server.channels.select { |c| c.type == 4 }.map do |category|
            { id: category.id.to_s, position: category.position, name: category.name }
          end
        end

        def build_channels(server)
          server.channels.reject { |c| c.type == 4 }.map { |channel| channel_data(channel) }
        end

        def channel_data(channel)
          { id: channel.id.to_s, name: channel.name, category: channel.category&.name }
        end

        def build_members(server)
          members = server.members
          if members.length < MEMBER_DETAIL_THRESHOLD
            members.map do |member|
              { id: member.id.to_s, username: member.username, display_name: member.display_name }
            end
          else
            { count: members.length }
          end
        end
      end
    end
  end
end
