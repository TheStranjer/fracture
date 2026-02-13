#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'lib/fracture'

token = ENV.fetch('DISCORD_BOT_TOKEN')

discord_client = Fracture::DiscordClient.new(token: token)
server = Fracture::Server.new(discord_client: discord_client)
server.start
