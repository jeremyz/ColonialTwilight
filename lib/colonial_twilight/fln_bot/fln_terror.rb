# frozen_string_literal: true

module ColonialTwilight
  module FLNBotTerror
    def terror
      # return false if !available_resources.positive? && !extort
      return false if event_playable? && event_more_effective_than_terror?

      until (space = terror_1_priority(@board.search { |s| may_terror_1_in?(s) }).sample).nil?
        exc = space.fln_underground == 1 ? space : nil
        break if !available_resources.positive? && !extort(except: exc)

        apply_action @turn.operation_in(:terror, space, 1).terror
      end

      if last_campaign?
        until (space = @board.search { |s| may_terror_2_in?(s) }.sample).nil?
          exc = space.fln_underground == 1 ? space : nil
          break if !available_resources.positive? && !extort(except: exc)

          apply_action @turn.operation_in(:terror, space, 1).terror
        end
      end

      @turn.operation_done?
    end
  end
end
