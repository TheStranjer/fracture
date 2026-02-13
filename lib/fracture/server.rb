# frozen_string_literal: true

module Fracture
  class Server
    attr_reader :mcp_server, :discord_client

    def initialize(discord_client:)
      @discord_client = discord_client
      @mcp_server = build_mcp_server
    end

    def start
      transport = MCP::Server::Transports::StdioTransport.new(mcp_server)
      transport.open
    end

    private

    def build_mcp_server
      MCP::Server.new(
        name: 'fracture',
        version: '0.1.0',
        tools: tools,
        configuration: MCP::Configuration.new(protocol_version: '2025-06-18')
      )
    end

    def tools
      [
        Tools::GetGuilds.build(discord_client)
      ]
    end
  end
end
