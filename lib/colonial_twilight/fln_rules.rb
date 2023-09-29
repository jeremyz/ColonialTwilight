#! /usr/bin/env ruby
# frozen_string_literal: true

# rubocop:disable Style/Documentation
#
module ColonialTwilight
  module FLNRules
    # Rally 3.3.1 + France Track
    def may_rally_in?(space)
      space.sector? || (space.city? && !space.support?) || (space.country? && space.independent?)
    end

    def rally_spaces(board)
      board.search { |s| may_rally_in? s }
    end

    def may_agitate_in?(space)
      !space.country? && (space.fln_control? || space.fln_bases.positive?)
    end

    def agitate_spaces(spaces)
      spaces.select { |s| may_agitate_in? s }
    end

    # March 3.3.2

    # Attack 3.3.3
    def may_attack_in?(space)
      space.fln_cubes.positive? && space.gov.positive?
    end

    def attack_spaces(board)
      board.search { |s| may_attack_in? s }
    end

    # Terror 3.3.4
    def may_terror_in?(space)
      !space.country? && !space.pop.zero? && space.fln_underground.positive?
    end

    def terror_spaces(board)
      board.search { |s| may_terror_in? s }
    end

    # Extort 4.3.1
    def may_extort_in?(space)
      !space.pop.zero? && space.fln_underground.positive? && space.fln_control? &&
        (space.country? ? space.independent? : true)
    end

    def extort_spaces(board)
      board.search { |s| may_extort_in? s }
    end

    # Subvert 4.3.2
    def may_subvert_in?(space)
      space.fln_underground.positive? && space.algerian_cubes.positive?
    end

    def subvert_spaces(board)
      board.search { |s| may_subvert_in? s }
    end

    # Ambush 4.3.3
    def may_ambush_in?(space)
      may_attack_in?(space)
    end

    def ambush_spaces(board)
      board.search { |s| may_ambush_in? s }
    end

    # OAS 5.3.1
    def may_oas_in?(space)
      !space.country? && !space.pop.zero? && !space.terror.positive?
    end

    def oas_spaces(board)
      board.search { |s| may_oas_in? s }
    end
  end
end
