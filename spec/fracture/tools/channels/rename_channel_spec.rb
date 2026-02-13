# frozen_string_literal: true

require 'json'

RSpec.describe Fracture::Tools::RenameChannel do
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
    it 'is rename_channel' do
      expect(described_class.name_value).to eq('rename_channel')
    end
  end

  describe '.call' do
    let(:channel) { instance_double(Discordrb::Channel, id: 3001) }
    let(:server) { instance_double(Discordrb::Server, channels: [channel]) }

    before do
      allow(discord_client).to receive(:server).with(111_222_333).and_return(server)
      allow(channel).to receive(:name=)
    end

    it 'returns an MCP tool response' do
      response = described_class.call(guild_id: '111222333', channel_id: '3001', name: 'renamed')
      expect(response).to be_a(MCP::Tool::Response)
    end

    it 'renames the channel' do
      expect(channel).to receive(:name=).with('renamed')
      described_class.call(guild_id: '111222333', channel_id: '3001', name: 'renamed')
    end

    it 'returns a success response' do
      parsed = parse_response(described_class.call(guild_id: '111222333', channel_id: '3001', name: 'renamed'))
      expect(parsed['success']).to be(true)
    end

    context 'when the guild is not found' do
      before do
        allow(discord_client).to receive(:server).with(999).and_return(nil)
      end

      it 'returns an error response' do
        parsed = parse_response(described_class.call(guild_id: '999', channel_id: '3001', name: 'renamed'))
        expect(parsed['error']).to eq('Guild not found: 999')
      end
    end

    context 'when the channel is not found' do
      it 'returns an error response' do
        parsed = parse_response(described_class.call(guild_id: '111222333', channel_id: '9999', name: 'renamed'))
        expect(parsed['error']).to eq('Channel not found: 9999')
      end
    end
  end

  def parse_response(response)
    JSON.parse(response.content.first[:text])
  end
end
