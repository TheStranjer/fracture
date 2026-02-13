# frozen_string_literal: true

require 'json'

RSpec.describe Fracture::Tools::SendMessage do
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
    it 'is send_message' do
      expect(described_class.name_value).to eq('send_message')
    end
  end

  describe '.call' do
    let(:channel) { instance_double(Discordrb::Channel) }
    let(:message_channel) { instance_double(Discordrb::Channel, id: 100_200_300) }
    let(:message) { instance_double(Discordrb::Message, id: 999_888_777, channel: message_channel) }

    before do
      allow(channel).to receive(:send_message).and_return(message)
    end

    context 'when sending to a guild channel' do
      before do
        allow(discord_client).to receive(:channel).with(100_200_300).and_return(channel)
      end

      it 'returns an MCP tool response' do
        response = described_class.call(guild_id: '111222333', channel_id: '100200300', content: 'hello')
        expect(response).to be_a(MCP::Tool::Response)
      end

      it 'sends the message to the channel' do
        expect(channel).to receive(:send_message).with('hello')
        described_class.call(guild_id: '111222333', channel_id: '100200300', content: 'hello')
      end

      it 'returns success with message and channel IDs' do
        parsed = parse_response(described_class.call(guild_id: '111222333', channel_id: '100200300', content: 'hello'))
        expect(parsed).to eq('success' => true, 'message_id' => '999888777', 'channel_id' => '100200300')
      end
    end

    context 'when sending a DM' do
      before do
        allow(discord_client).to receive(:pm_channel).with(1001).and_return(channel)
      end

      it 'sends the message via PM channel' do
        expect(channel).to receive(:send_message).with('hello')
        described_class.call(user_id: '1001', content: 'hello')
      end

      it 'returns success with message and channel IDs' do
        parsed = parse_response(described_class.call(user_id: '1001', content: 'hello'))
        expect(parsed).to eq('success' => true, 'message_id' => '999888777', 'channel_id' => '100200300')
      end
    end

    context 'with attachments' do
      before do
        allow(discord_client).to receive(:channel).with(100_200_300).and_return(channel)
      end

      it 'includes attachments in the message text' do
        expect(channel).to receive(:send_message).with("hello\nhttps://example.com/image.png")
        described_class.call(content: 'hello',
                             guild_id: '111222333',
                             channel_id: '100200300',
                             attachments: ['https://example.com/image.png'])
      end

      it 'sends attachments without content' do
        expect(channel).to receive(:send_message).with('https://example.com/image.png')
        described_class.call(guild_id: '111222333',
                             channel_id: '100200300',
                             attachments: ['https://example.com/image.png'])
      end

      it 'sends multiple attachments' do
        expect(channel).to receive(:send_message).with("https://example.com/a.png\nhttps://example.com/b.png")
        described_class.call(guild_id: '111222333',
                             channel_id: '100200300',
                             attachments: %w[https://example.com/a.png https://example.com/b.png])
      end
    end

    context 'when neither channel_id nor user_id is provided' do
      it 'returns an error response' do
        parsed = parse_response(described_class.call(content: 'hello'))
        expect(parsed['error']).to eq('Provide channel_id or user_id')
      end
    end

    context 'when neither content nor attachments is provided' do
      before do
        allow(discord_client).to receive(:channel).with(100_200_300).and_return(channel)
      end

      it 'returns an error response' do
        parsed = parse_response(described_class.call(guild_id: '111222333', channel_id: '100200300'))
        expect(parsed['error']).to eq('Provide content and/or attachments')
      end

      it 'returns an error for empty attachments' do
        parsed = parse_response(described_class.call(guild_id: '111222333', channel_id: '100200300', attachments: []))
        expect(parsed['error']).to eq('Provide content and/or attachments')
      end
    end
  end

  def parse_response(response)
    JSON.parse(response.content.first[:text])
  end
end
