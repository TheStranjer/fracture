# frozen_string_literal: true

RSpec.describe Fracture::DiscordClient do
  subject(:client) { described_class.new(token: 'test-token') }

  before do
    allow(Discordrb::Bot).to receive(:new).and_return(bot)
    allow(bot).to receive(:run)
  end

  let(:bot) { instance_double(Discordrb::Bot) }

  describe '#initialize' do
    it 'creates a Discordrb::Bot with the given token' do
      expect(Discordrb::Bot).to receive(:new).with(token: 'test-token', intents: :all)
      client
    end

    it 'starts the bot asynchronously' do
      expect(bot).to receive(:run).with(:async)
      client
    end
  end

  describe '#bot' do
    it 'returns the underlying bot instance' do
      expect(client.bot).to eq(bot)
    end
  end

  describe '#servers' do
    let(:servers_hash) { { 123 => double('server') } } # rubocop:disable RSpec/VerifiedDoubles

    before do
      allow(bot).to receive(:servers).and_return(servers_hash)
    end

    it 'delegates to the bot' do
      expect(client.servers).to eq(servers_hash)
    end
  end
end
