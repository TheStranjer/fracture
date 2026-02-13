# frozen_string_literal: true

require 'json'

RSpec.describe Fracture::Tools::CreateRole do
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
    it 'is create_role' do
      expect(described_class.name_value).to eq('create_role')
    end
  end

  describe '.call' do
    let(:role) { instance_double(Discordrb::Role, id: 5001) }
    let(:server) { instance_double(Discordrb::Server) }

    before do
      allow(discord_client).to receive(:server).with(111_222_333).and_return(server)
      allow(server).to receive(:create_role).and_return(role)
    end

    it 'returns an MCP tool response' do
      response = described_class.call(guild_id: '111222333', name: 'TestRole')
      expect(response).to be_a(MCP::Tool::Response)
    end

    it 'creates a role with the given parameters' do
      expect(server).to receive(:create_role).with(
        name: 'TestRole',
        colour: an_instance_of(Discordrb::ColourRGB),
        hoist: true,
        mentionable: true,
        permissions: an_instance_of(Discordrb::Permissions)
      )
      described_class.call(
        guild_id: '111222333', name: 'TestRole', colour: 0xFF0000,
        hoist: true, mentionable: true, permissions: %w[send_messages read_messages]
      )
    end

    it 'returns the new role ID' do
      parsed = parse_response(described_class.call(guild_id: '111222333', name: 'TestRole'))
      expect(parsed['success']).to be(true)
      expect(parsed['role_id']).to eq('5001')
    end

    it 'uses defaults for optional parameters' do
      expect(server).to receive(:create_role).with(
        name: 'BasicRole',
        colour: an_instance_of(Discordrb::ColourRGB),
        hoist: false,
        mentionable: false,
        permissions: an_instance_of(Discordrb::Permissions)
      )
      described_class.call(guild_id: '111222333', name: 'BasicRole')
    end

    context 'when the guild is not found' do
      before do
        allow(discord_client).to receive(:server).with(999).and_return(nil)
      end

      it 'returns an error response' do
        parsed = parse_response(described_class.call(guild_id: '999', name: 'TestRole'))
        expect(parsed['error']).to eq('Guild not found: 999')
      end
    end
  end

  def parse_response(response)
    JSON.parse(response.content.first[:text])
  end
end
