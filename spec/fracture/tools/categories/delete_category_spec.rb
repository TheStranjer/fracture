# frozen_string_literal: true

require 'json'

RSpec.describe Fracture::Tools::DeleteCategory do
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
    it 'is delete_category' do
      expect(described_class.name_value).to eq('delete_category')
    end
  end

  describe '.call' do
    let(:category) { instance_double(Discordrb::Channel, id: 2001, type: 4) }
    let(:text_channel) { instance_double(Discordrb::Channel, id: 3001, type: 0) }
    let(:server) { instance_double(Discordrb::Server, channels: [category, text_channel]) }

    before do
      allow(discord_client).to receive(:server).with(111_222_333).and_return(server)
      allow(category).to receive(:delete)
    end

    it 'returns an MCP tool response' do
      response = described_class.call(guild_id: '111222333', category_id: '2001')
      expect(response).to be_a(MCP::Tool::Response)
    end

    it 'deletes the category' do
      expect(category).to receive(:delete)
      described_class.call(guild_id: '111222333', category_id: '2001')
    end

    it 'returns a success response' do
      parsed = parse_response(described_class.call(guild_id: '111222333', category_id: '2001'))
      expect(parsed['success']).to be(true)
    end

    context 'when the guild is not found' do
      before do
        allow(discord_client).to receive(:server).with(999).and_return(nil)
      end

      it 'returns an error response' do
        parsed = parse_response(described_class.call(guild_id: '999', category_id: '2001'))
        expect(parsed['error']).to eq('Guild not found: 999')
      end
    end

    context 'when the category is not found' do
      it 'returns an error response' do
        parsed = parse_response(described_class.call(guild_id: '111222333', category_id: '9999'))
        expect(parsed['error']).to eq('Category not found: 9999')
      end
    end
  end

  def parse_response(response)
    JSON.parse(response.content.first[:text])
  end
end
