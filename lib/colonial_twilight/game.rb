#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

require 'json'

require 'colonial_twilight/board'
require 'colonial_twilight/cards'
require 'colonial_twilight/player'
require 'colonial_twilight/fln_bot'
require 'colonial_twilight/gov_player'

module ColonialTwilight

  class Game

    @scenarios = ['Short:  1960-1962: The End Game',
                  'Medium: 1957-1962: Midgame Development',
                  'Full:   1955-1962: Algérie Francaise!'].freeze
    @rules = ['Standard Rules      - No Support Phase in final Propaganda round',
              'Optional Rule 8.5.1 - Conduct Support Phase in final Propaganda round'].freeze
    @actions = {
      :event        => 'Event:                        execute the Event card',
      :ope_special  => 'Operation & Special Activity: conduct an Operation in any number of spaces with a Special Activity',
      :ope_only     => 'Operation Only:               conduct an Operation in any number of spaces without a Special Activity',
      :ope_limited  => 'Limited Operation:            conduct an Operation in 1 space without a Special Activity',
      :pass         => 'Pass:                         increase your Resources'
    }.freeze
    @swap_actions= [:ope_special, :ope_limited]
    class << self
      attr_reader :scenarios, :rules, :actions, :cards
    end
    def rules; Game.rules end
    def scenarios; Game.scenarios end
    def possible_actions used=nil
      ks = Game.actions.keys
      if not used.nil?
        if used == :event
          ks.delete :event
          ks.delete :ope_only
          ks.delete :ope_limited
        elsif used == :ope_special
          ks.delete :ope_special
          ks.delete :ope_only
        elsif used == :ope_limited
          ks.delete :ope_limited
          ks.delete :event
        elsif used == :ope_only
          ks.delete :ope_only
          ks.delete :event
          ks.delete :ope_special
        end
      end
      Game.actions.select { |k,v| ks.include? k }
    end

    attr_reader :options, :scenario, :ruleset, :board, :ui, :cards, :actions
    def initialize options
      @options = options
      @board = ColonialTwilight::Board.new
      @deck = ColonialTwilight::Deck.new
    end

    def start ui, s, rs
      @ui = ui
      @ruleset = rs
      @scenario = s
      @board.load [:short, :medium, :long][s]
      @max_card = 71
      @turn = 0
      @cards = []
      @actions = []
      @players = [FLNBot.new(self, :FLN), GOVPlayer.new(self, :GOV)]
      play
    end

    def current_card; @cards[-1] end

    def play
      save_board 0
      while true
        @turn += 1
        ui.turn_start @turn, *@players
        c = ui.pull_card @max_card
        c = 1 # FIXME
        @cards << @deck.pull(c)
        ui.show_card @cards[-1]
        File.open("actions-#{@turn}.json",'w') { |f| f << JSON.generate([]) }

        ui.continue? @players[0].instance_of? FLNBot
        ui.player @players[0], true
        @actions[0] = @players[0].play possible_actions
        @ui.adjust_track  @board.compute_victory_points
        save_board 0

        ui.continue? @players[1].instance_of? FLNBot
        ui.player @players[1], false
        @actions[1] = @players[1].play possible_actions @actions[0]
        @ui.adjust_track @board.compute_victory_points
        save_board 1

        @cards.shift if @cards.length > 2
        @players[0], @players[1] = @players[1], @players[0] if eligibility_swap?
        @actions.clear
      end
    end

    def eligibility_swap?
      Game.swap_actions.include? @actions[0]
    end

    def save_board phase
      json = JSON.generate @board.data
      File.open("turn-#{@turn}-#{phase}.json",'w') { |f| f << json }
    end

    def action_done player, action
      data = nil
      File.open("actions-#{@turn}.json",'r') { |f| data = JSON.load f }
      data << action

      json = JSON.generate data
      File.open("actions-#{@turn}.json",'w') { |f| f << json }
      @ui.show_player_action player, action
    end

  end

  class Sector
    def to_json *args
      name.to_json args
    end
  end

  class Box
    def to_json *args
      name.to_json args
    end
  end

end
