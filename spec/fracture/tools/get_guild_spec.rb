# frozen_string_literal: true

require 'json'

RSpec.describe Fracture::Tools::GetGuild do
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
    it 'is get_guild' do
      expect(described_class.name_value).to eq('get_guild')
    end
  end

  describe '.call' do
    let(:categories) do
      [
        instance_double(Discordrb::Channel, id: 900, type: 4, position: 0, name: 'Text Channels'),
        instance_double(Discordrb::Channel, id: 901, type: 4, position: 1, name: 'Voice Channels')
      ]
    end

    let(:channels) do
      categories + [
        instance_double(Discordrb::Channel, id: 800, type: 0, name: 'general', category: categories[0]),
        instance_double(Discordrb::Channel, id: 801, type: 2, name: 'voice-chat', category: categories[1]),
        instance_double(Discordrb::Channel, id: 802, type: 0, name: 'uncategorized', category: nil)
      ]
    end

    let(:members) do
      [
        instance_double(Discordrb::Member, id: 1001, username: 'alice', display_name: 'Alice'),
        instance_double(Discordrb::Member, id: 1002, username: 'bob', display_name: 'Bob the Builder')
      ]
    end

    let(:server) do
      instance_double(
        Discordrb::Server,
        id: 111_222_333,
        name: 'Test Server',
        region_id: 'us-east',
        channels: channels,
        members: members
      )
    end

    before do
      allow(discord_client).to receive(:server).with(111_222_333).and_return(server)
    end

    it 'returns an MCP tool response' do
      response = described_class.call(guild_id: '111222333')
      expect(response).to be_a(MCP::Tool::Response)
    end

    it 'returns the guild ID as a string' do
      parsed = parse_response(described_class.call(guild_id: '111222333'))
      expect(parsed['id']).to eq('111222333')
    end

    it 'returns the guild name' do
      parsed = parse_response(described_class.call(guild_id: '111222333'))
      expect(parsed['name']).to eq('Test Server')
    end

    it 'returns the region ID' do
      parsed = parse_response(described_class.call(guild_id: '111222333'))
      expect(parsed['region_id']).to eq('us-east')
    end

    it 'returns categories with id, position, and name' do
      parsed = parse_response(described_class.call(guild_id: '111222333'))
      expect(parsed['categories']).to contain_exactly(
        { 'id' => '900', 'position' => 0, 'name' => 'Text Channels' },
        { 'id' => '901', 'position' => 1, 'name' => 'Voice Channels' }
      )
    end

    it 'returns non-category channels with id, name, and category name' do
      parsed = parse_response(described_class.call(guild_id: '111222333'))
      expect(parsed['channels']).to contain_exactly(
        { 'id' => '800', 'name' => 'general', 'category' => 'Text Channels' },
        { 'id' => '801', 'name' => 'voice-chat', 'category' => 'Voice Channels' },
        { 'id' => '802', 'name' => 'uncategorized', 'category' => nil }
      )
    end

    it 'returns member details when under 100 members' do
      parsed = parse_response(described_class.call(guild_id: '111222333'))
      expect(parsed['members']).to contain_exactly(
        { 'id' => '1001', 'username' => 'alice', 'display_name' => 'Alice' },
        { 'id' => '1002', 'username' => 'bob', 'display_name' => 'Bob the Builder' }
      )
    end

    context 'when the guild has 100 or more members' do
      let(:members) do
        Array.new(100) do |i|
          instance_double(Discordrb::Member, id: 2000 + i, username: "user#{i}", display_name: "User #{i}")
        end
      end

      it 'returns only the member count' do
        parsed = parse_response(described_class.call(guild_id: '111222333'))
        expect(parsed['members']).to eq({ 'count' => 100 })
      end
    end

    context 'when the guild has no channels' do
      let(:channels) { [] }

      it 'returns empty categories and channels' do
        parsed = parse_response(described_class.call(guild_id: '111222333'))
        expect(parsed['categories']).to eq([])
        expect(parsed['channels']).to eq([])
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
