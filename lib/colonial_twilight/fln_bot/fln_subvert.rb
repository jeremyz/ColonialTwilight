# frozen_string_literal: true

module ColonialTwilight
  module FLNBotSubvert
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
  end
end
