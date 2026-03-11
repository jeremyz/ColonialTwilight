# frozen_string_literal: true

module ColonialTwilight
  module FLNBotRally
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
  end
end
