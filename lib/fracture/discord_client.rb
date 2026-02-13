# frozen_string_literal: true

module Fracture
  class DiscordClient
    attr_reader :bot

    def initialize(token:)
      @bot = Discordrb::Bot.new(token: token, intents: :all)
      @bot.run(:async)
    end

    def servers
      bot.servers
    end

    def server(id)
      bot.servers[id]
    end
  end
end
