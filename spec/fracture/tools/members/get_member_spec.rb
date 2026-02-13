# frozen_string_literal: true

require 'json'

RSpec.describe Fracture::Tools::GetMember do
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
    it 'is get_member' do
      expect(described_class.name_value).to eq('get_member')
    end
  end

  describe '.call' do
    let(:boosting_time) { Time.new(2024, 6, 15, 12, 0, 0, '+00:00') }
    let(:joined_time) { Time.new(2023, 1, 10, 8, 30, 0, '+00:00') }

    let(:game) { instance_double(Discordrb::Activity, name: 'Elden Ring', type: 0, url: nil) }
    let(:colour_role) { instance_double(Discordrb::Role, id: 5001) }
    let(:colour) { instance_double(Discordrb::ColourRGB, combined: 0xFF5733) }
    let(:highest_role) { instance_double(Discordrb::Role, id: 5002) }
    let(:hoist_role) { instance_double(Discordrb::Role, id: 5003) }
    let(:voice_channel) { instance_double(Discordrb::Channel, id: 7001) }

    let(:member) do
      instance_double(
        Discordrb::Member,
        boosting_since: boosting_time,
        joined_at: joined_time,
        display_name: 'Alice',
        username: 'alice',
        game: game,
        status: :online,
        colour: colour,
        colour_role: colour_role,
        deaf: false,
        highest_role: highest_role,
        hoist_role: hoist_role,
        mute: false,
        owner?: false,
        voice_channel: voice_channel,
        avatar_url: 'https://cdn.discordapp.com/avatars/1001/abc.png'
      )
    end

    let(:server) { instance_double(Discordrb::Server) }

    before do
      allow(discord_client).to receive(:server).with(111_222_333).and_return(server)
      allow(server).to receive(:member).with(1001).and_return(member)
    end

    it 'returns an MCP tool response' do
      response = described_class.call(guild_id: '111222333', member_id: '1001')
      expect(response).to be_a(MCP::Tool::Response)
    end

    it 'returns identity fields' do
      parsed = parse_response(described_class.call(guild_id: '111222333', member_id: '1001'))
      expect(parsed['display_name']).to eq('Alice')
      expect(parsed['user_name']).to eq('alice')
      expect(parsed['boosting_since']).to eq(boosting_time.iso8601)
      expect(parsed['joined_at']).to eq(joined_time.iso8601)
      expect(parsed['avatar_url']).to eq('https://cdn.discordapp.com/avatars/1001/abc.png')
    end

    it 'returns activity fields' do
      parsed = parse_response(described_class.call(guild_id: '111222333', member_id: '1001'))
      expect(parsed['game']).to eq('Elden Ring')
      expect(parsed['stream_type']).to eq(0)
    end

    it 'returns role fields' do
      parsed = parse_response(described_class.call(guild_id: '111222333', member_id: '1001'))
      expect(parsed['colour']).to eq(0xFF5733)
      expect(parsed['colour_role']).to eq('5001')
      expect(parsed['highest_role']).to eq('5002')
      expect(parsed['hoist_role']).to eq('5003')
    end

    it 'returns voice and status fields' do
      parsed = parse_response(described_class.call(guild_id: '111222333', member_id: '1001'))
      expect(parsed['status']).to eq('online')
      expect(parsed['deaf']).to be(false)
      expect(parsed['muted']).to be(false)
      expect(parsed['voice_channel']).to eq('7001')
    end

    context 'when member has no game activity' do
      let(:game) { nil }

      it 'omits game, stream_type, and stream_url from output' do
        parsed = parse_response(described_class.call(guild_id: '111222333', member_id: '1001'))
        expect(parsed).not_to have_key('game')
        expect(parsed).not_to have_key('stream_type')
        expect(parsed).not_to have_key('stream_url')
      end
    end

    context 'when member has no colour role' do
      let(:colour_role) { nil }
      let(:colour) { nil }

      it 'omits colour and colour_role from output' do
        parsed = parse_response(described_class.call(guild_id: '111222333', member_id: '1001'))
        expect(parsed).not_to have_key('colour')
        expect(parsed).not_to have_key('colour_role')
      end
    end

    context 'when member is not boosting' do
      let(:boosting_time) { nil }

      it 'omits boosting_since from output' do
        parsed = parse_response(described_class.call(guild_id: '111222333', member_id: '1001'))
        expect(parsed).not_to have_key('boosting_since')
      end
    end

    context 'when member is not in a voice channel' do
      let(:voice_channel) { nil }

      it 'omits voice_channel from output' do
        parsed = parse_response(described_class.call(guild_id: '111222333', member_id: '1001'))
        expect(parsed).not_to have_key('voice_channel')
      end
    end

    context 'when member is the server owner' do
      let(:member) do
        instance_double(
          Discordrb::Member,
          boosting_since: nil, joined_at: joined_time, display_name: 'Owner', username: 'owner',
          game: nil, status: :online, colour: nil, colour_role: nil, deaf: nil, highest_role: nil,
          hoist_role: nil, mute: nil, owner?: true, voice_channel: nil,
          avatar_url: 'https://cdn.discordapp.com/avatars/1001/abc.png'
        )
      end

      it 'includes owner as true' do
        parsed = parse_response(described_class.call(guild_id: '111222333', member_id: '1001'))
        expect(parsed['owner']).to be(true)
      end
    end

    context 'when member is not the server owner' do
      it 'omits owner from output' do
        parsed = parse_response(described_class.call(guild_id: '111222333', member_id: '1001'))
        expect(parsed).not_to have_key('owner')
      end
    end

    context 'when member is streaming' do
      let(:game) { instance_double(Discordrb::Activity, name: 'Elden Ring', type: 1, url: 'https://twitch.tv/alice') }

      it 'includes stream_type and stream_url' do
        parsed = parse_response(described_class.call(guild_id: '111222333', member_id: '1001'))
        expect(parsed['stream_type']).to eq(1)
        expect(parsed['stream_url']).to eq('https://twitch.tv/alice')
      end
    end

    context 'when the guild is not found' do
      before do
        allow(discord_client).to receive(:server).with(999).and_return(nil)
      end

      it 'returns an error response' do
        parsed = parse_response(described_class.call(guild_id: '999', member_id: '1001'))
        expect(parsed['error']).to eq('Guild not found: 999')
      end
    end

    context 'when the member is not found' do
      before do
        allow(server).to receive(:member).with(9999).and_return(nil)
      end

      it 'returns an error response' do
        parsed = parse_response(described_class.call(guild_id: '111222333', member_id: '9999'))
        expect(parsed['error']).to eq('Member not found: 9999')
      end
    end
  end

  def parse_response(response)
    JSON.parse(response.content.first[:text])
  end
end
