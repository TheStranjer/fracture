# frozen_string_literal: true

require 'json'

RSpec.describe Fracture::Tools::UnbanUser do
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
    it 'is unban_user' do
      expect(described_class.name_value).to eq('unban_user')
    end
  end

  describe '.call' do
    let(:server) { instance_double(Discordrb::Server) }

    before do
      allow(discord_client).to receive(:server).with(111_222_333).and_return(server)
      allow(server).to receive(:unban)
    end

    it 'returns an MCP tool response' do
      response = described_class.call(guild_id: '111222333', user_id: '1001', reason: 'appealed')
      expect(response).to be_a(MCP::Tool::Response)
    end

    it 'unbans the user with the given reason' do
      expect(server).to receive(:unban).with(1001, reason: 'appealed')
      described_class.call(guild_id: '111222333', user_id: '1001', reason: 'appealed')
    end

    it 'returns a success response' do
      parsed = parse_response(described_class.call(guild_id: '111222333', user_id: '1001', reason: 'appealed'))
      expect(parsed['success']).to be(true)
    end

    context 'when the guild is not found' do
      before do
        allow(discord_client).to receive(:server).with(999).and_return(nil)
      end

      it 'returns an error response' do
        parsed = parse_response(described_class.call(guild_id: '999', user_id: '1001', reason: 'appealed'))
        expect(parsed['error']).to eq('Guild not found: 999')
      end
    end
  end

  def parse_response(response)
    JSON.parse(response.content.first[:text])
  end
end
