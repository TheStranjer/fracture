# frozen_string_literal: true

require 'json'

RSpec.describe Fracture::Tools::ReadChannel do
  let(:discord_client) { instance_double(Fracture::DiscordClient) }

  before do
    described_class.build(discord_client)
  end

  describe '.build' do
    it 'sets the discord client' do
      expect(described_class.discord_client).to eq(discord_client)
    end

    it 'returns the class itself' do
      expect(described_class.build(discord_client)).to eq(described_class)
    end
  end

  describe '.tool_name' do
    it 'is read_channel' do
      expect(described_class.name_value).to eq('read_channel')
    end
  end

  describe '.call' do
    let(:server) { instance_double(Discordrb::Server) }
    let(:channel) { instance_double(Discordrb::Channel) }
    let(:timestamp) { Time.new(2025, 6, 15, 12, 30, 0, '+00:00') }
    let(:author) { instance_double(Discordrb::User, id: 111, display_name: 'TestUser') }
    let(:attachment) { instance_double(Discordrb::Attachment, url: 'https://cdn.example.com/img.png', filename: 'img.png') }

    let(:message) do
      instance_double(
        Discordrb::Message,
        id: 900_800_700,
        author: author,
        content: 'Hello world',
        attachments: [attachment],
        timestamp: timestamp
      )
    end

    before do
      allow(discord_client).to receive(:server).with(111_222_333).and_return(server)
      allow(discord_client).to receive(:channel).with(100_200_300).and_return(channel)
    end

    context 'with default parameters' do
      before do
        allow(channel).to receive(:history).with(100).and_return([message])
      end

      it 'returns an MCP tool response' do
        response = described_class.call(guild_id: '111222333', channel_id: '100200300')
        expect(response).to be_a(MCP::Tool::Response)
      end

      it 'fetches 100 messages by default' do
        expect(channel).to receive(:history).with(100)
        described_class.call(guild_id: '111222333', channel_id: '100200300')
      end

      it 'returns formatted messages' do
        parsed = parse_response(described_class.call(guild_id: '111222333', channel_id: '100200300'))
        expect(parsed['success']).to be(true)
        expect(parsed['messages'].length).to eq(1)
      end

      it 'includes author info' do
        parsed = parse_response(described_class.call(guild_id: '111222333', channel_id: '100200300'))
        msg = parsed['messages'].first
        expect(msg['author']).to eq('id' => '111', 'display_name' => 'TestUser')
      end

      it 'includes message content and attachments' do
        parsed = parse_response(described_class.call(guild_id: '111222333', channel_id: '100200300'))
        msg = parsed['messages'].first
        expect(msg['content']).to eq('Hello world')
        expect(msg['attachments']).to eq([{ 'url' => 'https://cdn.example.com/img.png', 'filename' => 'img.png' }])
      end

      it 'includes the timestamp' do
        parsed = parse_response(described_class.call(guild_id: '111222333', channel_id: '100200300'))
        expect(parsed['messages'].first['timestamp']).to eq(timestamp.iso8601)
      end
    end

    context 'with a custom limit' do
      before do
        allow(channel).to receive(:history).with(10).and_return([message])
      end

      it 'fetches the specified number of messages' do
        expect(channel).to receive(:history).with(10)
        described_class.call(guild_id: '111222333', channel_id: '100200300', limit: 10)
      end
    end

    context 'with an offset' do
      let(:older_message) { instance_double(Discordrb::Message, id: 500_600_700) }

      it 'skips the specified number of recent messages' do
        allow(channel).to receive(:history).with(5).and_return([older_message])
        allow(channel).to receive(:history).with(100, 500_600_700).and_return([message])
        expect(channel).to receive(:history).with(100, 500_600_700)
        described_class.call(guild_id: '111222333', channel_id: '100200300', offset: 5)
      end

      it 'returns empty when offset exceeds available messages' do
        allow(channel).to receive(:history).with(5).and_return([])
        parsed = parse_response(described_class.call(guild_id: '111222333', channel_id: '100200300', offset: 5))
        expect(parsed['messages']).to eq([])
      end
    end

    context 'with no messages' do
      before do
        allow(channel).to receive(:history).with(100).and_return([])
      end

      it 'returns an empty messages array' do
        parsed = parse_response(described_class.call(guild_id: '111222333', channel_id: '100200300'))
        expect(parsed['messages']).to eq([])
      end
    end

    context 'with a message that has no attachments' do
      let(:plain_message) do
        instance_double(
          Discordrb::Message,
          id: 900_800_700,
          author: author,
          content: 'No attachments here',
          attachments: [],
          timestamp: timestamp
        )
      end

      before do
        allow(channel).to receive(:history).with(100).and_return([plain_message])
      end

      it 'returns an empty attachments array' do
        parsed = parse_response(described_class.call(guild_id: '111222333', channel_id: '100200300'))
        expect(parsed['messages'].first['attachments']).to eq([])
      end
    end

    context 'when the guild is not found' do
      before do
        allow(discord_client).to receive(:server).with(999).and_return(nil)
      end

      it 'returns an error response' do
        parsed = parse_response(described_class.call(guild_id: '999', channel_id: '100200300'))
        expect(parsed['error']).to eq('Guild not found: 999')
      end
    end
  end

  def parse_response(response)
    JSON.parse(response.content.first[:text])
  end
end
