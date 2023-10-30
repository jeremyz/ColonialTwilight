#! /usr/bin/env ruby
# frozen_string_literal: true

module ColonialTwilight
  module FLNRules
    # Rally 3.3.1 + France Track
    def may_rally_in?(space)
      space.sector? || (space.city? && !space.support?) || (space.country? && space.independent?)
    end

    def rally_spaces(board)
      board.search(&method(:may_rally_in?))
    end

    def may_agitate_in?(space)
      !space.country? && (space.fln_control? || space.fln_bases.positive?) && (space.terror.positive? || !space.oppose?)
    end

    def agitate_spaces(board)
      board.search(&method(:may_agitate_in?))
    end

    def max_placable_guerrillas(space)
      space.fln_bases.positive? ? space.fln_bases + space.pop : 1
    end

    def max_agitate_cost(space)
      space.terror + (space.oppose? ? 0 : 1)
    end

    # March 3.3.2

    # Attack 3.3.3
    def may_attack_in?(space)
      space.guerrillas.positive? && space.gov.positive?
    end

    def attack_spaces(board)
      board.search(&method(:may_attack_in?))
    end

    # Terror 3.3.4
    def may_terror_in?(space)
      !space.country? && !space.pop.zero? && space.fln_underground.positive?
    end

    def terror_spaces(board)
      board.search(&method(:may_terror_in?))
    end

    # Extort 4.3.1
    def may_extort_in?(space)
      space.fln_underground.positive? && (space.country? ? space.independent? : !space.pop.zero? && space.fln_control?)
    end

    def extort_spaces(board)
      board.search(&method(:may_extort_in?))
    end

    # Subvert 4.3.2
    def may_subvert_in?(space)
      space.fln_underground.positive? && space.algerian_cubes.positive?
    end

    def subvert_spaces(board)
      board.search(&method(:may_subvert_in?))
    end

    # Ambush 4.3.3
    def may_ambush_in?(space)
      may_attack_in?(space)
    end

    def ambush_spaces(board)
      board.search(&method(:may_ambush_in?))
    end

    # OAS 5.3.1
    def may_oas_in?(space)
      !space.country? && !space.pop.zero? && !space.terror.positive?
    end

    def oas_spaces(board)
      board.search(&method(:may_oas_in?))
    end
  end
end
