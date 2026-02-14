# frozen_string_literal: true

module Fracture
  module Tools
    class ReadChannel < MCP::Tool
      tool_name 'read_channel'
      description 'Reads messages from a Discord channel. Returns author info, content, attachments, and timestamps.'
      input_schema(
        properties: {
          guild_id: {
            type: 'string',
            description: 'The ID of the guild'
          },
          channel_id: {
            type: 'string',
            description: 'The ID of the channel to read from'
          },
          limit: {
            type: 'integer',
            description: 'Number of messages to return (default 100, max 100)'
          },
          offset: {
            type: 'integer',
            description: 'Number of most-recent messages to skip (default 0)'
          }
        },
        required: %w[guild_id channel_id]
      )

      class << self
        attr_accessor :discord_client

        def build(discord_client)
          self.discord_client = discord_client
          self
        end

        def call(guild_id:, channel_id:, limit: 100, offset: 0)
          server = discord_client.server(guild_id.to_i)
          return error_response("Guild not found: #{guild_id}") unless server

          channel = discord_client.channel(channel_id.to_i)
          messages = fetch_messages(channel, limit, offset)

          success_response(messages)
        end

        private

        def fetch_messages(channel, limit, offset)
          if offset.positive?
            skipped = channel.history(offset)
            return [] if skipped.empty?

            channel.history(limit, skipped.last.id)
          else
            channel.history(limit)
          end
        end

        def format_message(msg)
          {
            id: msg.id.to_s,
            author: format_author(msg.author),
            content: msg.content,
            attachments: format_attachments(msg.attachments),
            timestamp: msg.timestamp.iso8601
          }
        end

        def format_author(author)
          { id: author.id.to_s, display_name: author.display_name }
        end

        def format_attachments(attachments)
          attachments.map { |a| { url: a.url, filename: a.filename } }
        end

        def success_response(messages)
          data = { success: true, messages: messages.map { |m| format_message(m) } }
          MCP::Tool::Response.new([{ type: 'text', text: data.to_json }])
        end

        def error_response(message)
          MCP::Tool::Response.new([{ type: 'text', text: { error: message }.to_json }])
        end
      end
    end
  end
end
