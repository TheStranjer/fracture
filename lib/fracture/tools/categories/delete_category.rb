# frozen_string_literal: true

module Fracture
  module Tools
    class DeleteCategory < MCP::Tool
      tool_name 'delete_category'
      description 'Deletes a category from a Discord guild'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild'
          },
          category_id: {
            type: 'string',
            description: 'The ID of the category to delete'
          }
        },
        required: %w[guild_id category_id]
      )

      class << self
        attr_accessor :discord_client

        def build(discord_client)
          self.discord_client = discord_client
          self
        end

        def call(guild_id:, category_id:)
          server = discord_client.server(guild_id.to_i)
          return error_response("Guild not found: #{guild_id}") unless server

          category = find_category(server, category_id)
          return error_response("Category not found: #{category_id}") unless category

          category.delete
          success_response
        end

        private

        def find_category(server, category_id)
          server.channels.find { |c| c.type == 4 && c.id == category_id.to_i }
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
