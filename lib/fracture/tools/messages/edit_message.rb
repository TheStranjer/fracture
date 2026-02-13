# frozen_string_literal: true

module Fracture
  module Tools
    class EditMessage < MCP::Tool
      tool_name 'edit_message'
      description 'Edits a message in a Discord channel or DM'
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
            description: 'The ID of the message to edit'
          },
          content: {
            type: 'string',
            description: 'The new content of the message'
          }
        },
        required: %w[message_id content]
      )

      class << self
        attr_accessor :discord_client

        def build(discord_client)
          self.discord_client = discord_client
          self
        end

        def call(message_id:, content:, guild_id: nil, channel_id: nil, user_id: nil) # rubocop:disable Lint/UnusedMethodArgument
          return error_response('Provide channel_id or user_id') unless channel_id || user_id

          channel = resolve_channel(channel_id, user_id)
          message = channel.load_message(message_id.to_i)
          return error_response("Message not found: #{message_id}") unless message

          message.edit(content)
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
