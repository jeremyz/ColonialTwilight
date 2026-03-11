# frozen_string_literal: true

require_relative 'player'
require_relative 'fln_bot/fln_rules'
require_relative 'fln_bot/fln_bot_rules'

require_relative 'fln_bot/fln_attack'
require_relative 'fln_bot/fln_extort'
require_relative 'fln_bot/fln_march'
require_relative 'fln_bot/fln_pass'
require_relative 'fln_bot/fln_rally'
require_relative 'fln_bot/fln_subvert'
require_relative 'fln_bot/fln_terror'

module ColonialTwilight
  class FLNBot < Player
    include ColonialTwilight::FLNRules
    include ColonialTwilight::FLNBotRules
    include ColonialTwilight::FLNRallyRules
    include ColonialTwilight::FLNExtortRules
    include ColonialTwilight::FLNSubvertRules
    include ColonialTwilight::FLNTerrorRules
    include ColonialTwilight::FLNAttackRules
    include ColonialTwilight::FLNGuidelines

    include ColonialTwilight::FLNBotAttack
    include ColonialTwilight::FLNBotExtort
    include ColonialTwilight::FLNBotMarch
    include ColonialTwilight::FLNBotPass
    include ColonialTwilight::FLNBotRally
    include ColonialTwilight::FLNBotSubvert
    include ColonialTwilight::FLNBotTerror

    def play_turn(prev_action, possible_actions)
      init_turn prev_action, possible_actions
      _start_turn
    end

    def printd(msg)
      return if @debug.zero?

      puts msg
    end

    ############################################################################

    def apply_action(action)
      @game.apply(:FLN, action)
    end

    def available_resources
      resources - (@reserved_to_agitate || 0)
    end

    def event_playable?
      # FIXME: event is FLN playable
      false
    end

    def event_more_effective_than_terror?
      # FIXME: event would reduce GOV victory margin by as much or more than terror
      false
    end

    def last_campaign?
      # FIXME: the next Propaganda Card will be the last one of the game
      true
    end
  end
end
