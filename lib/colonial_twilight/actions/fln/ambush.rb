# frozen_string_literal: true

require_relative 'fln_action'

module ColonialTwilight
  module Actions
    module FLN
      # Ambush 4.3.3 : max 2
      class Ambush < FlnAction
        def initialize(space)
          super(space, {}, 0)
        end

        # Activate only 1 Underground Guerrilla
        # Remove 1 Government piece (Police first, then Troops, then Base) into casualties
        # No Attrition
        # -1 Commitment per French Base removed
        def apply!(board)
          raise NotImplementedError
        end

        class << self
          def special?
            true
          end

          # any space where an Attack is occurring with Underground Guerrillas.
          def applicable?(space)
            Attack.applicable?(space) && space.fln_underground.positive?
          end
        end
      end
    end
  end
end
