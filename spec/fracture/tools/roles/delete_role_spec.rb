# frozen_string_literal: true

require 'json'

RSpec.describe Fracture::Tools::DeleteRole do
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
    it 'is delete_role' do
      expect(described_class.name_value).to eq('delete_role')
    end
  end

  describe '.call' do
    let(:role) { instance_double(Discordrb::Role, id: 5001) }
    let(:other_role) { instance_double(Discordrb::Role, id: 5002) }
    let(:server) { instance_double(Discordrb::Server, roles: [role, other_role]) }

    before do
      allow(discord_client).to receive(:server).with(111_222_333).and_return(server)
      allow(role).to receive(:delete)
    end

    it 'returns an MCP tool response' do
      response = described_class.call(guild_id: '111222333', role_id: '5001')
      expect(response).to be_a(MCP::Tool::Response)
    end

    it 'deletes the role' do
      expect(role).to receive(:delete)
      described_class.call(guild_id: '111222333', role_id: '5001')
    end

    it 'returns a success response' do
      parsed = parse_response(described_class.call(guild_id: '111222333', role_id: '5001'))
      expect(parsed['success']).to be(true)
    end

    context 'when the guild is not found' do
      before do
        allow(discord_client).to receive(:server).with(999).and_return(nil)
      end

      it 'returns an error response' do
        parsed = parse_response(described_class.call(guild_id: '999', role_id: '5001'))
        expect(parsed['error']).to eq('Guild not found: 999')
      end
    end

    context 'when the role is not found' do
      it 'returns an error response' do
        parsed = parse_response(described_class.call(guild_id: '111222333', role_id: '9999'))
        expect(parsed['error']).to eq('Role not found: 9999')
      end
    end
  end

  def parse_response(response)
    JSON.parse(response.content.first[:text])
  end
end
