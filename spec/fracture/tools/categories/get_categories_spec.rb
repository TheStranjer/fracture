# frozen_string_literal: true

require 'json'

RSpec.describe Fracture::Tools::GetCategories do
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
    it 'is get_categories' do
      expect(described_class.name_value).to eq('get_categories')
    end
  end

  describe '.call' do
    let(:allow_perms) { instance_double(Discordrb::Permissions, bits: 0x00000C00) }
    let(:deny_perms) { instance_double(Discordrb::Permissions, bits: 0x00000800) }
    let(:overwrite) { instance_double(Discordrb::Overwrite, type: :role, allow: allow_perms, deny: deny_perms) }
    let(:child_channel) do
      instance_double(Discordrb::Channel, id: 3001, name: 'general', type: 0, position: 0)
    end
    let(:category) do
      instance_double(
        Discordrb::Channel,
        id: 2001,
        name: 'Text Channels',
        type: 4,
        position: 0,
        permission_overwrites: { 5001 => overwrite },
        children: [child_channel]
      )
    end
    let(:text_channel) { instance_double(Discordrb::Channel, id: 3002, name: 'off-topic', type: 0) }
    let(:server) { instance_double(Discordrb::Server, channels: [category, text_channel]) }

    before do
      allow(discord_client).to receive(:server).with(111_222_333).and_return(server)
    end

    it 'returns an MCP tool response' do
      response = described_class.call(guild_id: '111222333')
      expect(response).to be_a(MCP::Tool::Response)
    end

    it 'returns only categories (type 4)' do
      parsed = parse_response(described_class.call(guild_id: '111222333'))
      expect(parsed.length).to eq(1)
      expect(parsed.first['name']).to eq('Text Channels')
    end

    it 'includes permission overwrites with decoded permissions' do
      parsed = parse_response(described_class.call(guild_id: '111222333'))
      overwrites = parsed.first['permission_overwrites']
      expect(overwrites.length).to eq(1)
      expect(overwrites.first['id']).to eq('5001')
      expect(overwrites.first['type']).to eq('role')
      expect(overwrites.first['allow']).to contain_exactly('read_messages', 'send_messages')
      expect(overwrites.first['deny']).to contain_exactly('send_messages')
    end

    it 'includes child channels' do
      parsed = parse_response(described_class.call(guild_id: '111222333'))
      children = parsed.first['channels']
      expect(children.length).to eq(1)
      expect(children.first['name']).to eq('general')
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
