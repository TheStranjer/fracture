# frozen_string_literal: true

module Fracture
  module Tools
    class DeleteMessage < MCP::Tool
      tool_name 'delete_message'
      description 'Deletes a message from a Discord channel or DM'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild (required with channel_id)'
          },
          channel_id: {
            type: 'string',
            description: 'The ID of the channel (requires guild_id)'
          },
          user_id: {
            type: 'string',
            description: 'The ID of the DM user (alternative to guild_id + channel_id)'
          },
          message_id: {
            type: 'string',
            description: 'The ID of the message to delete'
          }
        },
        required: ['message_id']
      )

      class << self
        attr_accessor :discord_client

        def build(discord_client)
          self.discord_client = discord_client
          self
        end

        def call(message_id:, guild_id: nil, channel_id: nil, user_id: nil) # rubocop:disable Lint/UnusedMethodArgument
          return error_response('Provide channel_id or user_id') unless channel_id || user_id

          channel = resolve_channel(channel_id, user_id)
          message = channel.load_message(message_id.to_i)
          return error_response("Message not found: #{message_id}") unless message

          message.delete
          success_response
        end

        private

        def resolve_channel(channel_id, user_id)
          if channel_id
            discord_client.channel(channel_id.to_i)
          else
            discord_client.pm_channel(user_id.to_i)
          end
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
