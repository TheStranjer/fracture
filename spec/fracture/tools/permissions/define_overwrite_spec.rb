# frozen_string_literal: true

require 'json'

RSpec.describe Fracture::Tools::DefineOverwrite do
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
    it 'is define_overwrite' do
      expect(described_class.name_value).to eq('define_overwrite')
    end
  end

  describe '.call' do
    let(:role) { instance_double(Discordrb::Role, id: 5001) }
    let(:member) { instance_double(Discordrb::Member, id: 1001) }
    let(:channel) { instance_double(Discordrb::Channel, id: 3001) }
    let(:server) do
      instance_double(Discordrb::Server, channels: [channel], roles: [role])
    end

    before do
      allow(discord_client).to receive(:server).with(111_222_333).and_return(server)
      allow(channel).to receive(:define_overwrite)
      allow(server).to receive(:member).with(1001).and_return(member)
    end

    context 'when type is role' do
      it 'defines an overwrite on the target channel for the role' do
        expect(channel).to receive(:define_overwrite).with(
          role,
          an_instance_of(Discordrb::Permissions),
          an_instance_of(Discordrb::Permissions),
          reason: 'testing'
        )

        described_class.call(
          guild_id: '111222333', type: 'role', id: '5001', target_id: '3001',
          allowed: %w[send_messages], denied: %w[manage_messages], reason: 'testing'
        )
      end

      it 'returns a success response' do
        parsed = parse_response(described_class.call(
                                  guild_id: '111222333', type: 'role', id: '5001', target_id: '3001',
                                  allowed: %w[send_messages], denied: %w[manage_messages], reason: 'testing'
                                ))
        expect(parsed['success']).to be(true)
      end
    end

    context 'when type is user' do
      it 'defines an overwrite on the target channel for the member' do
        expect(channel).to receive(:define_overwrite).with(
          member,
          an_instance_of(Discordrb::Permissions),
          an_instance_of(Discordrb::Permissions),
          reason: 'user override'
        )

        described_class.call(
          guild_id: '111222333', type: 'user', id: '1001', target_id: '3001',
          allowed: %w[read_messages], denied: [], reason: 'user override'
        )
      end
    end

    context 'when type is channel' do
      it 'defines an overwrite on the channel for the target role' do
        expect(channel).to receive(:define_overwrite).with(
          role,
          an_instance_of(Discordrb::Permissions),
          an_instance_of(Discordrb::Permissions),
          reason: 'channel lock'
        )

        described_class.call(
          guild_id: '111222333', type: 'channel', id: '3001', target_id: '5001',
          allowed: [], denied: %w[send_messages], reason: 'channel lock'
        )
      end
    end

    context 'when type is category' do
      let(:category) { instance_double(Discordrb::Channel, id: 2001) }
      let(:server) do
        instance_double(Discordrb::Server, channels: [category], roles: [role])
      end

      before do
        allow(category).to receive(:define_overwrite)
      end

      it 'defines an overwrite on the category for the target role' do
        expect(category).to receive(:define_overwrite).with(
          role,
          an_instance_of(Discordrb::Permissions),
          an_instance_of(Discordrb::Permissions),
          reason: 'category lock'
        )

        described_class.call(
          guild_id: '111222333', type: 'category', id: '2001', target_id: '5001',
          allowed: [], denied: %w[send_messages], reason: 'category lock'
        )
      end
    end

    context 'when the guild is not found' do
      before do
        allow(discord_client).to receive(:server).with(999).and_return(nil)
      end

      it 'returns an error response' do
        parsed = parse_response(described_class.call(
                                  guild_id: '999', type: 'role', id: '5001', target_id: '3001',
                                  allowed: [], denied: [], reason: 'test'
                                ))
        expect(parsed['error']).to eq('Guild not found: 999')
      end
    end

    context 'when the channel is not found' do
      it 'returns an error response' do
        parsed = parse_response(described_class.call(
                                  guild_id: '111222333', type: 'role', id: '5001', target_id: '9999',
                                  allowed: [], denied: [], reason: 'test'
                                ))
        expect(parsed['error']).to eq('Channel or category not found')
      end
    end

    context 'when the overwrite target is not found' do
      it 'returns an error response' do
        parsed = parse_response(described_class.call(
                                  guild_id: '111222333', type: 'role', id: '9999', target_id: '3001',
                                  allowed: [], denied: [], reason: 'test'
                                ))
        expect(parsed['error']).to eq('Overwrite target not found')
      end
    end
  end

  def parse_response(response)
    JSON.parse(response.content.first[:text])
  end
end
