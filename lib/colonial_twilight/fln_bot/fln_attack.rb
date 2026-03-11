# frozen_string_literal: true

module ColonialTwilight
  module FLNBotAttack
    def attack
      # return false if !available_resources.positive? && !extort

      n = 2
      ambush_cond = ->(s) { n.positive? && @turn.may_special_activity?(:ambush) && may_ambush_1_in?(s) }
      cond = ->(s) { may_attack_1_in?(s) || ambush_cond.call(s) }
      until (space = attack_priority(@board.search(&cond)).sample).nil?
        break if !available_resources.positive? && !extort

        _apply_attack(space, ambush_cond.call(space))
        n -= 1
      end

      until (space = attack_priority(@board.search { |s| may_attack_2_in?(s) }).sample).nil?
        break if !available_resources.positive? && !extort

        _apply_attack(space, ambush_cond.call(space))
        n -= 1
      end

      @turn.operation_done?
    end

    def _apply_attack(space, ambush)
      apply_action ambush ? _ambush(space) : _attack(space)
    end

    def _ambush(space)
      action = @turn.special_activity_in(:ambush, space, 1).activate(1)
      casualties = _casualties(space, action, 1)
      _attrition(action, casualties)
    end

    def _attack(space)
      action = @turn.operation_in(:attack, space, 1).activate(space.fln_underground)
      return action if (d = d6) > space.guerrillas

      casualties = _casualties(space, action, 2)
      _attrition(action, casualties)
      action.transfer_from(place_from, :fln_underground) if d == 1
      action
    end

    def _casualties(space, action, casualties)
      num = 0
      FLNAttackRules::CASUALTIES_PRIORITY.each do |sym|
        next unless (n = space.send(sym)).positive?

        casualties -= (n = (n > casualties ? casualties : n))
        num += n
        action.transfer_to(:casualties, sym, n)
        action.shift(:commitment, -1) if sym == :gov_bases
        break if casualties.zero?
      end
      num
    end

    def _attrition(action, casualties)
      action.transfer_to(:available, :fln_active, (casualties + 1) / 2)
            .transfer_to(:casualties, :fln_active, casualties / 2)
    end
  end
end
