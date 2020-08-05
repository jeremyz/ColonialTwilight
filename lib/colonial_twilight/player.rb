#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

module ColonialTwilight

  class Player

    attr_reader :faction

    def initialize game, faction
      @game = game
      @faction = faction
    end

    def to_s
      @faction.to_s
    end

    def play possible_actions
      action = @game.ui.chose( 'Choose an action', possible_actions.values) { |s| a = s.split(':'); a[0] = a[0].yellow; a.join(':') }
      puts 'Player.play' # FIXME
      return action
    end

  end

end
