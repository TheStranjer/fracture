# frozen_string_literal: true

require 'json'

RSpec.describe Fracture::Tools::GetGuilds do
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
    it 'is get_guilds' do
      expect(described_class.name_value).to eq('get_guilds')
    end
  end

  describe '.call' do
    let(:server_one) { instance_double(Discordrb::Server, name: 'Test Server') }
    let(:server_two) { instance_double(Discordrb::Server, name: 'Another Server') }
    let(:servers) { { 111_222_333 => server_one, 444_555_666 => server_two } }

    before do
      allow(discord_client).to receive(:servers).and_return(servers)
    end

    it 'returns an MCP tool response' do
      response = described_class.call
      expect(response).to be_a(MCP::Tool::Response)
    end

    it 'returns guild IDs and names as JSON' do
      response = described_class.call
      content = response.content.first
      parsed = JSON.parse(content[:text])

      expect(parsed).to contain_exactly(
        { 'id' => '111222333', 'name' => 'Test Server' },
        { 'id' => '444555666', 'name' => 'Another Server' }
      )
    end

    context 'when the bot is in no guilds' do
      let(:servers) { {} }

      it 'returns an empty array' do
        response = described_class.call
        content = response.content.first
        parsed = JSON.parse(content[:text])

        expect(parsed).to eq([])
      end
    end
  end
end
