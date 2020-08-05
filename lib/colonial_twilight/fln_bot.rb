#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

module ColonialTwilight

  class FLNBot

    attr_reader :faction

    def initialize game, faction
      @game = game
      @faction = faction
    end

    def play possible_actions
      puts 'FLNBot.play' #FIXME
    end

  end

end
