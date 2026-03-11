# frozen_string_literal: true

module ColonialTwilight
  module FLNBotExtort
    def extort(except: nil, to_agitate_in: nil)
      return false if available_resources > 4
      return false unless @turn.may_special_activity?(:extort)
      return false if (space = extort_priority(extortable(except: except)).sample).nil?

      apply_action @turn.special_activity_in(:extort, space, -1, to_agitate_in: to_agitate_in).extort
    end

    def extortable(except: nil)
      @board.search { |s| may_extort_0_in?(s) }.reject { |s| @turn.special_activity_selected?(s) || s == except }
    end
  end
end
