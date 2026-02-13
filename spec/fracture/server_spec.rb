# frozen_string_literal: true

RSpec.describe Fracture::Server do
  subject(:server) { described_class.new(discord_client: discord_client) }

  let(:discord_client) { instance_double(Fracture::DiscordClient) }

  describe '#initialize' do
    it 'creates an MCP server' do
      expect(server.mcp_server).to be_a(MCP::Server)
    end

    it 'exposes the discord client' do
      expect(server.discord_client).to eq(discord_client)
    end
  end

  describe '#mcp_server' do
    it 'has the correct server name' do
      expect(server.mcp_server.instance_variable_get(:@name)).to eq('fracture')
    end
  end

  describe '#start' do
    it 'opens a stdio transport' do
      transport = instance_double(MCP::Server::Transports::StdioTransport)
      allow(MCP::Server::Transports::StdioTransport).to receive(:new).and_return(transport)
      expect(transport).to receive(:open)

      server.start
    end
  end
end
