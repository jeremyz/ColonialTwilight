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

    def pass?
      # if resources = 0 && Op Limited as only choice
      r = @board.fln_resources.zero? && limited_op_only?
      dbg 'PASS', r
      r
    end

    def terror1?
      # unless any FLN base is (pop 0 && 0 FLN underground or pop 1+ && 1- FLN underground)
      r = !@board.has do |s|
        s.fln_bases.positive? &&
          ((s.pop.zero? && s.fln_underground.zero?) || (!s.pop.zero? && s.fln_underground < 2))
      end
      dbg 'TERROR 1', r
      r
    end

    def terror2?
      # if GOV is first eligible && will be second eligible
      r = !first_eligible? && will_be_next_first_eligible?
      dbg 'TERROR 2', r
      r
    end

    def rally1?
      # rally would place bases (first 2 bullets)
      # 4+ or (3+ FLN and no GOV (unless limited_op_only))
      r = @board.available_fln_bases.positive? && @board.has do |s|
        may_add_base_in?(s) && (rally_2_in?(s) || rally_1_in?(s))
      end
      dbg 'RALLY 1', r
      r
    end

    def rally2?
      # if #FLN bases * 2 > #FLN at FLN bases + 1d6/2
      a = @board.count(&:fln_bases) * 2
      b = @board.count { |s| s.fln_bases.zero? ? 0 : s.fln_cubes }
      r = a > (b + d6 / 2)
      dbg 'RALLY 2', r
      r
    end

    # Rally

    def may_add_base_in?(space)
      r = space.fln_cubes > 2 && (space.fln_bases < (space.country? ? space.max_bases : 1))
      dbg "  may_add_base : #{space.name}", r
      r
    end

    def rally_1_in?(space)
      # 3+ FLN and no GOV (unless limited_op_only))
      r = space.fln_cubes >= 3 && (limited_op_only? ? true : space.gov_cubes.zero?)
      dbg "  rally_1_in : #{space.name}", r
      r
    end

    def rally_2_in?(space)
      # 4+ FLN
      r = space.fln_cubes >= 4
      dbg "  rally_2_in : #{space.name}", r
      r
    end

    def rally_3_in?(space)
      # at FLN bases, with 2- FLN underground or 0 fln_undergroud in country or 0 pop
      r = !space.fln_bases.zero? &&
          (space.country? || space.pop.zero? ? space.fln_underground.zero? : space.fln_underground < 2)
      dbg "  rally_3_in : #{space.name}", r
      r
    end

    def rally_3_priority(spaces)
      # Algeria -> with cubes -> pop 1+ -> least FLN underground
      l0 = (l0 = spaces.reject(&:country?)).empty? ? spaces : l0
      l1 = (l1 = l0.select { |s| s.gov_cubes.positive? }).empty? ? l0 : l1
      l2 = (l2 = l1.select { |s| s.pop.positive? }).empty? ? l1 : l2
      l2.min { |a, b| a.fln_underground <=> b.fln_underground }
    end

    def rally_5_in?(space)
      # non-city at support with 0 FLN underground
      r = !space.city? && space.support? && space.fln_underground.zero?
      dbg "  rally_5_in : #{space.name}", r
      r
    end

    def rally_6_in?(space)
      # 2+ pop to agitate
      r = space.pop > 1 && may_agitate_in?(space)
      dbg "  rally_6_in : #{space.name}", r
      r
    end

    def rally_8_in?(space)
      r = !space.fln_cubes.zero? && space.fln_bases.zero?
      dbg "  rally_8_in : #{space.name}", r
      r
    end

    # 8.1.2 - Procedure Guidelines
    def fln_to_place?
      @board.available_fln_underground.positive? || !place_from(@board.spaces).nil?
    end

    # 1) place: outofplay -> available | bases -> cubes if choice
    # 2) place: underground first unless from map then place active first flipped as underground
    # 3) march: underground -> active, unless march would activate then move active first

    def place_in(spaces)
      # 4) support -> with friendly pieces -> random
      l0 = (l0 = spaces.select(&:support?)).empty? ? spaces : l0
      l1 = (l1 = l0.select { |s| s.fln_cubes.positive? }).empty? ? l0 : l1
      (l1.empty? ? @board.spaces : l1).sample
    end

    def place_from(spaces)
      # 5) active only, leave 2 cubes at base or support, most cubes first
      l = spaces.select do |s|
        s.fln_active.positive? && (s.support? || s.fln_bases.positive? ? s.fln_cubes > 2 : true)
      end
      return nil if l.empty?

      v = l.max { |a, b| a.fln_cubes <=> b.fln_cubes }.fln_cubes
      l.select { |s| s.fln_cubes == v }.sample
    end

    def remove_from(space, num = 1)
      # 6) remove active -> underground -> base
      h = {}
      num -= h[:fln_active] = (s = space.fln_active) >= num ? num : s
      num -= h[:fln_underground] = (s = space.fln_underground) >= num ? num : s
      h[:fln_bases] = (s = space.fln_bases) >= num ? num : s
      h
    end

    def remove_gov(num = 1)
      # 7) map -> availabe (base -> french -> algerian; troops -> police)
    end

      # 8) reduce : commitment -> support -> france track -> gov resource
      # 9) shift : support -> oppose | best combined; remove terror only if also shift
      # 10) random
  end
end
