# frozen_string_literal: true

require 'json'

RSpec.describe Fracture::Tools::GetGuildRoles do
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
    it 'is get_guild_roles' do
      expect(described_class.name_value).to eq('get_guild_roles')
    end
  end

  describe '.call' do
    let(:colour) { instance_double(Discordrb::ColourRGB, combined: 0xFF0000) }
    let(:permissions) { instance_double(Discordrb::Permissions, bits: 0x00000806) }
    let(:role) do
      instance_double(
        Discordrb::Role,
        id: 5001,
        name: 'Moderator',
        colour: colour,
        hoist: true,
        managed: false,
        mentionable: true,
        permissions: permissions
      )
    end
    let(:server) { instance_double(Discordrb::Server, roles: [role]) }

    before do
      allow(discord_client).to receive(:server).with(111_222_333).and_return(server)
    end

    it 'returns an MCP tool response' do
      response = described_class.call(guild_id: '111222333')
      expect(response).to be_a(MCP::Tool::Response)
    end

    it 'returns role metadata' do
      parsed = parse_response(described_class.call(guild_id: '111222333'))
      role_data = parsed.first
      expect(role_data['id']).to eq('5001')
      expect(role_data['name']).to eq('Moderator')
      expect(role_data['colour']).to eq(0xFF0000)
      expect(role_data['hoist']).to be(true)
    end

    it 'returns decoded permissions' do
      parsed = parse_response(described_class.call(guild_id: '111222333'))
      role_data = parsed.first
      expect(role_data['permissions']).to contain_exactly('kick_members', 'ban_members', 'send_messages')
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
