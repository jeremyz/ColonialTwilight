#! /usr/bin/env ruby
# frozen_string_literal: true

require 'colonial_twilight/player'
require 'colonial_twilight/fln_rules'
require 'colonial_twilight/fln_bot_rules'

module ColonialTwilight
  class FLNBot < Player
    include ColonialTwilight::FLNRules
    include ColonialTwilight::FLNBotRules

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

    # PASS #####################################################################

    def pass
      apply_action @turn.pass(1)
    end

    # EXTORT ###################################################################

    def extort(except: nil, to_agitate_in: nil)
      return false if available_resources > 4
      return false unless @turn.may_special_activity?(:extort)
      return false if (space = extort_priority(extortable(except: except)).sample).nil?

      apply_action @turn.special_activity_in(:extort, space, -1, to_agitate_in: to_agitate_in).extort
    end

    def extortable(except: nil)
      @board.search { |s| may_extort_0_in?(s) }.reject { |s| @turn.special_activity_selected?(s) || s == except }
    end

    # TERROR ###################################################################

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

    # ATTACK ###################################################################

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
      CASUALTIES_PRIORITY.each do |sym|
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

    # SUBVERT ##################################################################

    def subvert
      return false if (spaces = subvert_spaces(@board)).empty?

      n = 2
      while n.positive?
        printd('  subvert 1')
        break if (space = subvert_1_priority(spaces.select { |s| may_subvert_1_in?(s, n) }).sample).nil?

        n -= space.algerian_cubes
        apply_action _subvert_remove(space, space.algerian_police, space.algerian_troops)
        spaces.delete(space)
      end
      return true if n.zero? || spaces.empty?

      if n == 2 && placeable_guerrillas?
        printd('  subvert 2')
        unless (space = spaces.select { |s| may_subvert_2_in?(s) }.sample).nil?
          apply_action _subvert_replace(space, pick_guerrillas_from)
          return true
        end
      end
      return false if n == 2 && !@turn.operation_done?

      spaces.shuffle!
      while n.positive? && !(space = spaces.pop).nil?
        printd('  subvert 3')
        n -= (p = (p = space.algerian_police) > n ? n : p)
        n -= (t = (t = space.algerian_troops) > n ? n : t)
        apply_action _subvert_remove(space, p, t)
      end
      n != 2
    end

    def _subvert_remove(space, police, troops)
      @turn.special_activity_in(:subvert, space, 0)
           .transfer_to(:available, :algerian_police, police)
           .transfer_to(:available, :algerian_troops, troops)
    end

    def _subvert_replace(space, place_from)
      @turn.special_activity_in(:subvert, space, 0)
           .transfer_to(:available, :algerian_police, 1)
           .transfer_from(place_from, :fln_underground, 1)
    end

    # RALLY ####################################################################

    def rally
      # return false if !available_resources.positive? && !extort

      @reserved_to_agitate = 0
      # max 6 spaces
      max_selected = (limited_op_only? ? 1 : 6)
      # max 2/3 resources unless starts with < 9 resources
      max_resources = (@board.fln_resources < 9 ? 0 : @board.fln_resources * 2 / 3)
      max_cost = -> { max_resources.zero? ? 0 : max_resources - @turn.cost }

      stop_cond = if max_resources.zero?
                    -> { @turn.selected_spaces >= max_selected }
                  else
                    -> { @turn.selected_spaces >= max_selected || (@turn.cost + @reserved_to_agitate) >= max_resources }
                  end
      stop_cond_base = -> { !available_fln_bases? || stop_cond.call }

      loop do
        break unless _place_base_in(_rally(1, stop_cond_base, ->(s) { may_rally_1_in?(s) }))
      end

      loop do
        break unless _place_base_in(_rally(2, stop_cond_base, ->(s) { may_rally_2_in?(s) }))
      end

      loop do
        break unless _place_fln_in(_rally(3, stop_cond, ->(s) { may_rally_3_in?(s) }, priority: 3))
      end

      _shift_france_track unless stop_cond.call

      loop do
        break unless _place_fln_in(_rally(5, stop_cond, ->(s) { may_rally_5_in?(s) }, priority: 5))
      end

      unless stop_cond.call
        printd('  rally 6')
        filter = ->(s) { may_rally_6_in?(s, @turn.operation_selected?(s)) }
        space = _rally_one_space(filter, priority: 6, reselect: true)
        if _reserve_to_agitate_in?(space, max_cost.call)
          agitate_in = space
          _place_fln_in(space, to_agitate_in: space) unless @turn.operation_selected?(space)
        end
      end

      2.times do
        break unless _place_fln_in(_rally(7, stop_cond, ->(s) { may_rally_7_in?(s) }, priority: 7))
      end

      2.times do
        break unless _place_fln_in(_rally(8, stop_cond, ->(s) { may_rally_8_in?(s) }, priority: 8))
      end

      if agitate_in.nil?
        printd '  rally 9'
        filter = ->(s) { may_rally_9_in?(s) && (@turn.operation_selected?(s) || @turn.selected_spaces < max_selected) }
        spaces = rally_9_priority(@board.search(&filter), max_cost.call) { |s| @turn.operation_selected?(s) }.shuffle
        while (space = spaces.pop)
          if @turn.operation_selected?(space)
            agitate_in = space
          elsif _reserve_to_agitate_in?(space, max_cost.call) && _place_fln_in(space, to_agitate_in: space)
            agitate_in = space
          end
          break unless agitate_in.nil?
        end
      end
      _agitate_in(agitate_in, max_cost.call)

      @turn.operation_done?
    end

    def _rally(num, stop_cond, filter, priority: nil, reselect: false)
      return nil if stop_cond.call

      printd("  rally #{num}")
      return nil if (space = _rally_one_space(filter, priority: priority, reselect: reselect)).nil?

      printd("    -> #{space.name}")
      extort unless available_resources.positive?

      available_resources.positive? ? space : nil
    end

    def _rally_one_space(filter, priority: nil, reselect: false)
      spaces = @board.search(&filter)
      spaces = spaces.reject(&@turn.method('operation_selected?')) unless reselect
      spaces = _place_priority(spaces, priority) unless priority.nil?
      spaces.sample
    end

    def _place_priority(spaces, priority)
      return spaces if spaces.size < 2

      spaces = case priority
               when 3 then rally_3_priority(spaces)
               when 5 then rally_5_priority(spaces)
               when 6 then rally_6_priority(spaces)
               when 7 then rally_7_priority(spaces)
               else spaces
               end
      place_guerrillas_priority(spaces)
    end

    def _place_base_in(space)
      return false if space.nil?

      printd "    => _place_base_in : #{space.name}"
      a, u = (n = space.fln_active) >= 2 ? [2, 0] : [n, 2 - n]
      apply_action @turn.operation_in(:rally, space, 1)
                        .transfer_to(:available, :fln_active, a)
                        .transfer_to(:available, :fln_underground, u)
                        .transfer_from(:available, :fln_base)
    end

    def _place_fln_in(space, to_agitate_in: nil)
      return false if space.nil?

      printd "    => _place_fln_in : #{space.name}"
      return false if (steps = place_guerrillas_in(space)).empty?

      apply_action @turn.operation_in(:rally, space, 1, to_agitate_in: to_agitate_in).transfer_steps(steps)
    end

    def _shift_france_track
      printd('  rally 4')
      return false if @board.france_track.zero?

      extort unless available_resources.positive?
      apply_action @turn.operation_in(:rally, :france_track, 1).shift(1)
    end

    def _agitate_in(space, max_cost)
      return if space.nil?

      printd "    => _agitate_in : #{space.name}"
      terror = space.terror
      oppose = space.oppose? ? 0 : 1
      if @reserved_to_agitate.positive?
        terror = terror > @reserved_to_agitate ? @reserved_to_agitate : terror
        oppose = 0 if terror == @reserved_to_agitate
        return apply_action @turn.agitate_in(space, terror, oppose)
      end

      if max_cost.positive? && (cost = (terror + oppose)) > max_cost
        terror -= (cost - oppose - max_cost)
        oppose = 0
      end
      return if terror.zero?

      if (cost = terror + oppose) < available_resources
        return apply_action @turn.agitate_in(space, terror, oppose)
      end

      max_rcs = available_resources + extortable.size
      if cost > max_rcs
        terror -= (cost - oppose - max_rcs)
        oppose = 0
      end
      return if terror.zero?

      ((terror + oppose) - available_resources).times { extort(to_agitate_in: space) }
      apply_action @turn.agitate_in(space, terror, oppose)
    end

    def _reserve_to_agitate_in?(space, max_cost)
      return false if space.nil?

      printd "    => _reserve_to_agitate_in : #{space.name}"
      cost = (rally_cost = (@turn.operation_selected?(space) ? 0 : 1)) + (agitate_cost = max_agitate_cost(space))
      agitate_cost -= (cost - max_cost) if max_cost.positive? && cost > max_cost
      return false unless agitate_cost.positive?

      if (cost = (rally_cost + agitate_cost)) < available_resources
        @reserved_to_agitate = agitate_cost
        return true
      end
      max_rcs = available_resources + extortable.size
      agitate_cost -= (cost - max_rcs) if cost > max_rcs
      return false unless agitate_cost.positive?

      ((rally_cost + agitate_cost) - available_resources).times { extort(to_agitate_in: space) }
      @reserved_to_agitate = agitate_cost
      true
    end

    # MARCH# ###################################################################

    def march
      return false if event_playable? && event_more_effective_than_terror?

      # FIXME
    end
  end
end
