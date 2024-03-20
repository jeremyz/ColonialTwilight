#! /usr/bin/env ruby
# frozen_string_literal: true

require 'json'

require 'colonial_twilight/board'
require 'colonial_twilight/cards'
require 'colonial_twilight/player'
require 'colonial_twilight/fln_bot'
require 'colonial_twilight/gov_player'

module ColonialTwilight
  class Game

    MAX_CARD = 71

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
      attr_reader :scenarios, :rules, :actions
    end
    def rules; Game.rules end
    def scenarios; Game.scenarios end
    def possible_actions used
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
      @board.load [:short, :medium, :full][s]
      @turn = 0
      @cards = {
        :current => @deck.pull(0),
        :prev => @deck.pull(0)
      }
      @actions = []
      @players = {
        :fln => FLNBot.new(self, :FLN),
        :gov => GOVPlayer.new(self, :GOV),
        :first => :fln,
        :second => :gov
      }
    end

    def current_card
      @cards[:current]
    end

    def first
      @players[@players[:first]]
    end

    def second
      @players[@players[:second]]
    end

    def eligibility_swap
      @players[:first], @players[:second] = @players[:second], @players[:first]
    end

    def eligibility_swap?
      Game.swap_actions.include? @actions[0]
    end

    def play
      while true
        @turn += 1
        ui.turn_start @turn, first, second
        _pull_card

        act = _play first, nil
        @ui.adjust_track  @board.compute_victory_points
        act = _play second, act
        @ui.adjust_track  @board.compute_victory_points

        eligibility_swap if eligibility_swap?
        @actions.clear
      end
    end

    def action_done player, action
      File.open("actions-#{@turn}.json",'r+') do |f|
        data = JSON.load f
        data << action
        f.seek 0
        f << JSON.generate(data)
      end
      @ui.show_player_action player, action
    end

    private

    def _play player, prev_act
      _save prev_act.nil?
      ui.continue? player.instance_of? FLNBot
      ui.player player, prev_act.nil?
      player.play possible_actions prev_act
    end

    def _pull_card
      @cards[:prev] = @cards[:current]
      @cards[:current] = @deck.pull ui.pull_card(MAX_CARD)
      ui.show_card @cards[:current]
    end

    def _save first
      h = {
        :ruleset => @ruleset,
        :scenario => @scenario,
        :turn => @turn,
        :cards => {:current => @cards[:current].num, :prev => @cards[:prev].num},
        :players => {:first => @players[:first], :second => @players[:second]},
        :board => @board.data
      }
      File.open("turn-#{@turn}-#{first ? 0 : 1}.json",'w') { |f| f << JSON.generate(h) }
      File.open("actions-#{@turn}.json",'w') { |f| f << JSON.generate([]) }
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
