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
      [guild_tools, ban_tools, member_tools, message_tools, role_tools, category_tools, channel_tools,
       permission_tools].flatten
    end

    def guild_tools
      [
        Tools::GetGuilds.build(discord_client),
        Tools::GetGuild.build(discord_client),
        Tools::GetGuildMembers.build(discord_client)
      ]
    end

    def ban_tools
      [
        Tools::BanUser.build(discord_client),
        Tools::UnbanUser.build(discord_client),
        Tools::GetGuildBans.build(discord_client)
      ]
    end

    def member_tools
      [
        Tools::GetMember.build(discord_client),
        Tools::AddRole.build(discord_client),
        Tools::RemoveRole.build(discord_client)
      ]
    end

    def message_tools
      [
        Tools::SendMessage.build(discord_client),
        Tools::DeleteMessage.build(discord_client),
        Tools::EditMessage.build(discord_client)
      ]
    end

    def role_tools
      [
        Tools::GetGuildRoles.build(discord_client),
        Tools::CreateRole.build(discord_client),
        Tools::DeleteRole.build(discord_client)
      ]
    end

    def category_tools
      [
        Tools::GetCategories.build(discord_client),
        Tools::CreateCategory.build(discord_client),
        Tools::DeleteCategory.build(discord_client),
        Tools::EditCategory.build(discord_client)
      ]
    end

    def channel_tools
      [
        Tools::CreateChannel.build(discord_client),
        Tools::DeleteChannel.build(discord_client),
        Tools::RenameChannel.build(discord_client)
      ]
    end

    def permission_tools
      [
        Tools::DefineOverwrite.build(discord_client)
      ]
    end
  end
end
