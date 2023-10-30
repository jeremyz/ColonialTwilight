#! /usr/bin/env ruby
# frozen_string_literal: true

module ColonialTwilight
  module FLNBotRules
    def dbg(msg, ret)
      return if @debug.zero?

      case @debug
      when 1 then puts "  #{msg} : YES" if ret
      else puts "  #{msg} : #{ret ? 'YES' : 'NO'}"
      end
    end

    def pass?(board = @board)
      # if resources = 0 && Op Limited as only choice
      r = board.fln_resources.zero? && limited_op_only?
      dbg 'PASS', r
      r
    end

    def terror1?(board = @board)
      # if no FLN base is (pop 0 && 0 FLN underground or pop 1+ && 1- FLN underground)
      r = !board.has do |s|
        s.fln_bases.positive? && ((s.pop.zero? && s.fln_underground.zero?) || (!s.pop.zero? && s.fln_underground < 2))
      end
      dbg 'TERROR 1', r
      r
    end

    def terror2?(_board = nil)
      # if GOV is first eligible && will be second eligible
      r = !first_eligible? && will_be_next_first_eligible?
      dbg 'TERROR 2', r
      r
    end

    def rally1?(board = @board)
      # rally would place a base (rally 1 or 2)
      r = board.available_fln_bases.positive? && board.has { |s| (may_rally_1_in?(s) || may_rally_2_in?(s)) }
      dbg 'RALLY 1', r
      r
    end

    def rally2?(board = @board)
      # if #FLN bases * 2 > #FLN at FLN bases + 1d6/2
      a = board.count(&:fln_bases) * 2
      b = board.count { |s| s.fln_bases.zero? ? 0 : s.guerrillas }
      r = a > (b + d6 / 2)
      dbg 'RALLY 2', r
      r
    end

    # Rally

    def may_rally_1_in?(space)
      # 3+ FLN and no GOV (unless limited_op_only))
      r = may_rally_in?(space) && may_add_base_in?(space) && space.guerrillas >= 3 &&
          (limited_op_only? ? true : space.gov_cubes.zero?)
      dbg "  may_rally_1_in : #{space.name}", r
      r
    end

    def may_rally_2_in?(space)
      # 4+ FLN
      r = may_rally_in?(space) && may_add_base_in?(space) && space.guerrillas >= 4
      dbg "  may_rally_2_in : #{space.name}", r
      r
    end

    def may_rally_3_in?(space)
      # at FLN bases, with 2- FLN underground or 0 fln_undergroud in country or 0 pop
      r = may_rally_in?(space) && !space.fln_bases.zero? &&
          (space.country? || space.pop.zero? ? space.fln_underground.zero? : space.fln_underground < 2)
      dbg "  may_rally_3_in : #{space.name}", r
      r
    end

    def rally_3_priority(spaces)
      # Algeria -> with cubes -> pop 1+ -> least FLN underground
      f = _filter(spaces) { |s| !s.country? }
      f = _filter(f) { |s| s.gov_cubes.positive? }
      f = _filter(f) { |s| s.pop.positive? }
      _min(f, :fln_underground)
    end

    def may_rally_5_in?(space)
      # non-city at support with 0 FLN underground
      r = may_rally_in?(space) && !space.city? && space.support? && space.fln_underground.zero?
      dbg "  may_rally_5_in : #{space.name}", r
      r
    end

    def rally_5_priority(spaces)
      # highest population
      _max(spaces, :pop)
    end

    def may_rally_6_in?(space, already_rallied)
      # 2+ pop to agitate after rally
      r = (already_rallied || may_rally_in?(space)) && space.pop > 1 && (space.terror.positive? || !space.oppose?)
      if r
        # may agitate if : FLN base or control after rally
        n = already_rallied ? 0 : place_guerrillas_in(space).values.sum
        r &= (space.fln_bases.positive? || (space.gov < (space.fln + n)))
      end
      dbg "  may_rally_6_in : #{space.name}", r
      r
    end

    def rally_6_priority(spaces)
      # max pop, min terror, support : reference ?
      f = _max(spaces, :pop)
      f = _min(f, :terror)
      _filter(f, &:support?)
      # FIXME: maybe already selected first, or not
    end

    def may_rally_7_in?(space)
      r = may_rally_in?(space)
      dbg "  may_rally_7_in : #{space.name}", r
      r
    end

    def rally_7_priority(spaces)
      # highest population -> gain FLN control -> remove Gov control -> city -> least terror
      f = _max(spaces, :pop)
      f = _filter(f) { |s| s.gov < s.fln + place_guerrillas_in(s).values.sum }
      f = _filter(f) { |s| s.gov == s.fln + place_guerrillas_in(s).values.sum }
      f = _filter(f, &:city?)
      _min(f, :terror)
    end

    def may_rally_8_in?(space)
      r = may_rally_in?(space) && !space.guerrillas.zero? && space.fln_bases.zero?
      dbg "  may_rally_8_in : #{space.name}", r
      r
    end

    def rally_8_priority(spaces)
      # Algeria -> most Guerrillas -> no gov cubes
      f = _filter(spaces) { |s| !s.country? }
      f = _max(f, :guerrillas)
      _filter(f) { |s| s.gov_cubes.zero? }
    end

    # 8.1.2 - Procedure Guidelines

    def _filter(spaces, &block)
      (f = spaces.select(&block)).empty? ? spaces : f
    end

    def _max(spaces, sym)
      v = spaces.max { |a, b| a.send(sym) <=> b.send(sym) }.send(sym)
      spaces.select { |s| s.send(sym) == v }
    end

    def _min(spaces, sym)
      v = spaces.min { |a, b| a.send(sym) <=> b.send(sym) }.send(sym)
      spaces.select { |s| s.send(sym) == v }
    end

    def available_fln_bases?(board = @board)
      board.available_fln_bases.positive?
    end

    def may_add_base_in?(space)
      space.guerrillas > 2 && (space.fln_bases < (space.country? ? space.max_bases : 1))
    end

    def max_placable_guerrillas_in?(space)
      max_placable_guerrillas(space).clamp(0, space.fln_bases.positive? ? (space.pop + 1 - space.guerrillas) : 666)
    end

    def place_guerrillas_in(space, board = @board)
      n = max_placable_guerrillas_in?(space)
      h = { space: 0 } # do not select space
      n -= h[:available] = (a = board.available_fln_underground) >= n ? n : a
      while n.positive? && !(spaces = _remove_guerrillas_priority(board.spaces, h)).empty?
        s = spaces.sample
        n -= h[s] = (g = _removable_guerrillas(s)) >= n ? n : g
      end
      h.reject { |_k, v| v.zero? }
    end

    # 1) place: outofplay -> available | bases -> guerrillas if choice
    # 2) place: underground first unless from map then place active first flipped as underground
    # 3) march: underground -> active, unless march would activate then move active first

    # applied as last filter in FLNBot#_place_fln
    def place_guerrillas(spaces)
      # 4) support -> with friendly pieces -> random
      f = _filter(spaces, &:support?)
      _filter(f) { |s| s.guerrillas.positive? }
    end

    # place_guerrillas_in
    def _removable_guerrillas(space)
      # 5) active only, leave 2 guerrillas at base or support
      a = (a = space.fln_underground) > 2 ? 2 : a
      n = space.fln_active - (space.support? || space.fln_bases.positive? ? (2 - a) : 0)
      n.positive? ? n : 0
    end

    def _not_selected(spaces, selected)
      spaces.reject { |s| selected.key?(s) }
    end

    # place_guerrillas_in
    def _remove_guerrillas_priority(spaces, selected)
      # 5) #removable_guerrillas then most guerrillas first
      return [] if (l = _not_selected(spaces, selected).select { |s| _removable_guerrillas(s).positive? }).empty?

      _max(l, :guerrillas).shuffle
    end

    # not used yet
    def remove_from(space, num = 1)
      # 6) remove active -> underground -> base
      h = {}
      num -= h[:fln_active] = (s = space.fln_active) >= num ? num : s
      num -= h[:fln_underground] = (s = space.fln_underground) >= num ? num : s
      h[:fln_bases] = (s = space.fln_bases) >= num ? num : s
      h
    end

    # 7) remove gov : map -> availabe (base -> french -> algerian; troops -> police)
    # 8) reduce : commitment -> support -> france track -> gov resource
    # 9) shift : support -> oppose | best combined; remove terror only if also shift
    # 10) random
  end
end
