# frozen_string_literal: true

require 'json'

RSpec.describe Fracture::Tools::GetGuildBans do
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
    it 'is get_guild_bans' do
      expect(described_class.name_value).to eq('get_guild_bans')
    end
  end

  describe '.call' do
    let(:user_alice) { instance_double(Discordrb::User, id: 1001) }
    let(:user_bob) { instance_double(Discordrb::User, id: 1002) }
    let(:bans) do
      [
        instance_double(Discordrb::ServerBan, user: user_alice, reason: 'spamming'),
        instance_double(Discordrb::ServerBan, user: user_bob, reason: 'harassment')
      ]
    end
    let(:server) { instance_double(Discordrb::Server, bans: bans) }

    before do
      allow(discord_client).to receive(:server).with(111_222_333).and_return(server)
    end

    it 'returns an MCP tool response' do
      response = described_class.call(guild_id: '111222333')
      expect(response).to be_a(MCP::Tool::Response)
    end

    it 'returns all bans with user_id and reason' do
      parsed = parse_response(described_class.call(guild_id: '111222333'))
      expect(parsed).to contain_exactly(
        { 'user_id' => '1001', 'reason' => 'spamming' },
        { 'user_id' => '1002', 'reason' => 'harassment' }
      )
    end

    context 'when the guild has no bans' do
      let(:bans) { [] }

      it 'returns an empty array' do
        parsed = parse_response(described_class.call(guild_id: '111222333'))
        expect(parsed).to eq([])
      end
    end

    context 'when the guild is not found' do
      before do
        allow(discord_client).to receive(:server).with(999).and_return(nil)
      end

      it 'returns an error response' do
        parsed = parse_response(described_class.call(guild_id: '999'))
        expect(parsed['error']).to eq('Guild not found: 999')
      end
    end
  end

  def parse_response(response)
    JSON.parse(response.content.first[:text])
  end
end
