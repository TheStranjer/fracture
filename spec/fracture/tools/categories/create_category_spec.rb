# frozen_string_literal: true

require 'json'

RSpec.describe Fracture::Tools::CreateCategory do
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
    it 'is create_category' do
      expect(described_class.name_value).to eq('create_category')
    end
  end

  describe '.call' do
    let(:category) { instance_double(Discordrb::Channel, id: 2001) }
    let(:server) { instance_double(Discordrb::Server) }

    before do
      allow(discord_client).to receive(:server).with(111_222_333).and_return(server)
      allow(server).to receive(:create_channel).and_return(category)
    end

    it 'returns an MCP tool response' do
      response = described_class.call(guild_id: '111222333', name: 'New Category', position: 0)
      expect(response).to be_a(MCP::Tool::Response)
    end

    it 'creates a category channel (type 4)' do
      expect(server).to receive(:create_channel).with('New Category', 4, position: 0)
      described_class.call(guild_id: '111222333', name: 'New Category', position: 0)
    end

    it 'returns the new category ID' do
      parsed = parse_response(described_class.call(guild_id: '111222333', name: 'New Category', position: 0))
      expect(parsed['success']).to be(true)
      expect(parsed['category_id']).to eq('2001')
    end

    context 'when the guild is not found' do
      before do
        allow(discord_client).to receive(:server).with(999).and_return(nil)
      end

      it 'returns an error response' do
        parsed = parse_response(described_class.call(guild_id: '999', name: 'New Category', position: 0))
        expect(parsed['error']).to eq('Guild not found: 999')
      end
    end
  end

  def parse_response(response)
    JSON.parse(response.content.first[:text])
  end
end
