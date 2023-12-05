#! /usr/bin/env ruby
# frozen_string_literal: true

require 'colonial_twilight/turn'

module ColonialTwilight
  class Player
    attr_reader :faction, :game, :turn

    def initialize(game, faction)
      @game = game
      @board = game.board
      @faction = faction
      @debug = game.options.debug
      @turn = Turn.new
    end

    def resources
      @faction == :FLN ? @board.fln_resources : @board.gov_resources
    end

    def score
      @faction == :FLN ? @board.opposition_bases : @board.support_commitment
    end

    private

    def init_turn(prev_action, possible_actions)
      @prev_action = prev_action
      @possible_actions = possible_actions
      @card = @game.current_card
      @turn.reset(limited_op_only?)
    end

    def d6
      @game.d6
    end

    def first_eligible?
      @game.first == self
    end

    def will_be_next_first_eligible?
      Game.swap_actions.include? @prev_action
    end

    def may_play_event?
      @possible_actions.include?(:event)
    end

    def limited_op_only?
      @possible_actions.size == 2 && @possible_actions.include?(:op_limited)
    end

    def limited_op_done?
      limited_op_only? && !@turn.operation_done?
    end
  end
end
