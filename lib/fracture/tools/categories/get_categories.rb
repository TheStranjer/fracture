# frozen_string_literal: true

module Fracture
  module Tools
    class GetCategories < MCP::Tool
      tool_name 'get_categories'
      description 'Gets all categories and their full details for a Discord guild'
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

          categories = find_categories(server).map { |c| build_category_data(c) }
          MCP::Tool::Response.new([{ type: 'text', text: categories.to_json }])
        end

        private

        def find_categories(server)
          server.channels.select { |c| c.type == 4 }
        end

        def build_category_data(category)
          {
            id: category.id.to_s,
            name: category.name,
            position: category.position,
            permission_overwrites: build_overwrites(category),
            channels: build_children(category)
          }
        end

        def build_overwrites(category)
          category.permission_overwrites.map do |id, overwrite|
            build_overwrite_data(id, overwrite)
          end
        end

        def build_overwrite_data(id, overwrite)
          {
            id: id.to_s,
            type: overwrite.type,
            allow: Permissions.bits_to_array(overwrite.allow.bits),
            deny: Permissions.bits_to_array(overwrite.deny.bits)
          }
        end

        def build_children(category)
          category.children.map do |channel|
            { id: channel.id.to_s, name: channel.name, type: channel.type, position: channel.position }
          end
        end

        def error_response(message)
          MCP::Tool::Response.new([{ type: 'text', text: { error: message }.to_json }])
        end
      end
    end
  end
end
