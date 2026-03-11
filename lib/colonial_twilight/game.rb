# frozen_string_literal: true

require 'json'

require_relative 'board'
require_relative 'deck'
require_relative 'fln_bot'
require_relative 'gov_player'

module ColonialTwilight
  module GameDefinitions
    SCENARIOS = {
      short: 'Short:  1960-1962: The End Game',
      medium: 'Medium: 1957-1962: Midgame Development',
      full: 'Full:   1955-1962: Algérie Francaise!'
    }.freeze

    RULES = {
      std: 'Standard Rules      - No Support Phase in final Propaganda round',
      optional: 'Optional Rule 8.5.1 - Conduct Support Phase in final Propaganda round'
    }.freeze

    SWAP_ACTIONS = %i[op_special op_limited].freeze

    POSSIBLE_ACTIONS = {
      event: %i[pass op_special],
      op_special: %i[pass event op_limited],
      op_limited: %i[pass op_special op_only],
      op_only: %i[pass op_limited],
      pass: %i[pass event op_special op_limited op_only]
    }.freeze
  end

  class Game
    include GameDefinitions

    attr_reader :options, :board

    def initialize(options)
      @options = options
      @turn = 0
      @card = nil
      @board = ColonialTwilight::Board.new
      @deck = ColonialTwilight::Deck.new
      _set_ui
      _set_players
    end

    def inspect
      'Game'
    end

    def d6
      @ui.d6
    end

    def launch
      @ui.welcome

      s = @ui.chose_scenario SCENARIOS
      @scenario = SCENARIOS.keys[s]
      r = @ui.chose_rules RULES
      @ruleset = RULES.keys[r]

      @board.load @scenario
      # FIXME: do something with selected ruleset
      _play
    end

    def first
      @players[@players[:first]]
    end

    def second
      @players[@players[:second]]
    end

    def current_card
      @card
    end

    def apply(faction, action)
      _save_action(action)
      @board.apply(faction, action)
      @ui.show_action(action)
      true
    end

    private

    def _set_ui
      if @options.ui != :cli
        puts "Gui mode '#{@options.ui}' is not implemented"
        exit(1)
      end
      require_relative 'cli'
      @ui = ColonialTwilight::Cli.new @options
    end

    def _set_players
      @players = {
        FLN: FLNBot.new(self, :FLN),
        GOV: GOVPlayer.new(self, :GOV),
        first: :FLN,
        second: :GOV
      }
    end

    def _play
      loop do
        @turn += 1
        @ui.turn_start @turn, first, second
        _pull_card
        first_action = _play_turn first
        # FIXME : maybe it's not need to recompute and ask to display
        # @ui.adjust_track @board.compute_victory_points
        _play_turn second, first_action
        # @ui.adjust_track @board.compute_victory_points
        _swap_eligibility first_action
      end
    end

    def _pull_card
      @card = @deck.pull @ui.pull_card(ColonialTwilight::Card::MAX_CARD_NUM)
      @ui.show_card @card
    end

    def _swap_eligibility(first_action)
      return unless SWAP_ACTIONS.include? first_action

      @players[:first], @players[:second] = @players[:second], @players[:first]
    end

    def _play_turn(player, prev_act = nil)
      _save prev_act.nil?
      @ui.continue? player
      @ui.show_player player, prev_act.nil?
      player.play_turn prev_act, POSSIBLE_ACTIONS[prev_act || :pass]
    end

    # TEST
    def _save_action(action)
      # puts 'FIXME : Board::_save_action'
      # File.open("actions-#{@turn}.json", 'r+') do |f|
      #   data = JSON.parse f
      #   data << action
      #   f.seek 0
      #   f << JSON.generate(data)
      # end
    end

    def _save(first)
    # puts 'FIXME : Board::_save'
    #   h = {
    #     ruleset: @ruleset,
    #     scenario: @scenario,
    #     turn: @turn,
    #     card: @card,
    #     players: { first: @players[:first], second: @players[:second] },
    #     board: @board.data
    #   }
    #   File.open("turn-#{@turn}-#{first ? 0 : 1}.json", 'w') { |f| f << JSON.generate(h) }
    #   File.open("actions-#{@turn}.json", 'w') { |f| f << JSON.generate([]) }
    end
  end
end
