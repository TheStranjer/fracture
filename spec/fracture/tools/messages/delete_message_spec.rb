# frozen_string_literal: true

require 'json'

RSpec.describe Fracture::Tools::DeleteMessage do
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
    it 'is delete_message' do
      expect(described_class.name_value).to eq('delete_message')
    end
  end

  describe '.call' do
    let(:channel) { instance_double(Discordrb::Channel) }
    let(:message) { instance_double(Discordrb::Message) }

    before do
      allow(channel).to receive(:load_message).with(999_888_777).and_return(message)
      allow(message).to receive(:delete)
    end

    context 'when deleting from a guild channel' do
      before do
        allow(discord_client).to receive(:channel).with(100_200_300).and_return(channel)
      end

      it 'returns an MCP tool response' do
        response = described_class.call(guild_id: '111222333', channel_id: '100200300', message_id: '999888777')
        expect(response).to be_a(MCP::Tool::Response)
      end

      it 'deletes the message' do
        expect(message).to receive(:delete)
        described_class.call(guild_id: '111222333', channel_id: '100200300', message_id: '999888777')
      end

      it 'returns a success response' do
        parsed = parse_response(
          described_class.call(guild_id: '111222333', channel_id: '100200300', message_id: '999888777')
        )
        expect(parsed['success']).to be(true)
      end
    end

    context 'when deleting from a DM' do
      before do
        allow(discord_client).to receive(:pm_channel).with(1001).and_return(channel)
      end

      it 'resolves the DM channel and deletes the message' do
        expect(message).to receive(:delete)
        described_class.call(user_id: '1001', message_id: '999888777')
      end

      it 'returns a success response' do
        parsed = parse_response(described_class.call(user_id: '1001', message_id: '999888777'))
        expect(parsed['success']).to be(true)
      end
    end

    context 'when the message is not found' do
      before do
        allow(discord_client).to receive(:channel).with(100_200_300).and_return(channel)
        allow(channel).to receive(:load_message).with(404).and_return(nil)
      end

      it 'returns an error response' do
        parsed = parse_response(
          described_class.call(guild_id: '111222333', channel_id: '100200300', message_id: '404')
        )
        expect(parsed['error']).to eq('Message not found: 404')
      end
    end

    context 'when neither channel_id nor user_id is provided' do
      it 'returns an error response' do
        parsed = parse_response(described_class.call(message_id: '999888777'))
        expect(parsed['error']).to eq('Provide channel_id or user_id')
      end
    end
  end

  def parse_response(response)
    JSON.parse(response.content.first[:text])
  end
end
