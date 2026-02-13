# frozen_string_literal: true

require 'json'

RSpec.describe Fracture::Tools::GetGuildMembers do
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
    it 'is get_guild_members' do
      expect(described_class.name_value).to eq('get_guild_members')
    end
  end

  describe '.call' do
    let(:members) do
      [
        instance_double(Discordrb::Member, id: 1001, username: 'alice', display_name: 'Alice'),
        instance_double(Discordrb::Member, id: 1002, username: 'bob', display_name: 'Bob the Builder')
      ]
    end

    let(:server) do
      instance_double(Discordrb::Server, members: members)
    end

    before do
      allow(discord_client).to receive(:server).with(111_222_333).and_return(server)
    end

    it 'returns an MCP tool response' do
      response = described_class.call(guild_id: '111222333')
      expect(response).to be_a(MCP::Tool::Response)
    end

    it 'returns all members with id, username, and display_name' do
      parsed = parse_response(described_class.call(guild_id: '111222333'))
      expect(parsed).to contain_exactly(
        { 'id' => '1001', 'username' => 'alice', 'display_name' => 'Alice' },
        { 'id' => '1002', 'username' => 'bob', 'display_name' => 'Bob the Builder' }
      )
    end

    context 'when the guild has many members' do
      let(:members) do
        Array.new(200) do |i|
          instance_double(Discordrb::Member, id: 2000 + i, username: "user#{i}", display_name: "User #{i}")
        end
      end

      it 'returns all members regardless of count' do
        parsed = parse_response(described_class.call(guild_id: '111222333'))
        expect(parsed.length).to eq(200)
        expect(parsed.first).to eq({ 'id' => '2000', 'username' => 'user0', 'display_name' => 'User 0' })
        expect(parsed.last).to eq({ 'id' => '2199', 'username' => 'user199', 'display_name' => 'User 199' })
      end
    end

    context 'when the guild has no members' do
      let(:members) { [] }

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
