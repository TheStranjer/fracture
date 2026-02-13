# frozen_string_literal: true

module Fracture
  module Tools
    class SendMessage < MCP::Tool
      tool_name 'send_message'
      description 'Sends a message to a Discord channel or user via DM'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild (required with channel_id)'
          },
          channel_id: {
            type: 'string',
            description: 'The ID of the channel to send to (requires guild_id)'
          },
          user_id: {
            type: 'string',
            description: 'The ID of the user to DM (alternative to guild_id + channel_id)'
          },
          content: {
            type: 'string',
            description: 'The text content of the message'
          },
          attachments: {
            type: 'array',
            items: { type: 'string' },
            description: 'An array of attachment URLs to include in the message'
          }
        }
      )

      class << self
        attr_accessor :discord_client

        def build(discord_client)
          self.discord_client = discord_client
          self
        end

        def call(content: nil, attachments: nil, guild_id: nil, channel_id: nil, user_id: nil) # rubocop:disable Lint/UnusedMethodArgument
          return error_response('Provide channel_id or user_id') unless channel_id || user_id
          return error_response('Provide content and/or attachments') if content.nil? && attachments_empty?(attachments)

          text = build_message_text(content, attachments)
          channel = resolve_channel(channel_id, user_id)
          message = channel.send_message(text)

          success_response(message)
        end

        private

        def attachments_empty?(attachments)
          attachments.nil? || attachments.empty?
        end

        def build_message_text(content, attachments)
          parts = []
          parts << content if content
          parts.concat(attachments) if attachments&.any?
          parts.join("\n")
        end

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

        def success_response(message)
          data = { success: true, message_id: message.id.to_s, channel_id: message.channel.id.to_s }
          MCP::Tool::Response.new([{ type: 'text', text: data.to_json }])
        end
      end
    end
  end
end
