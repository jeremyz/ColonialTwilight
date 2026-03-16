# frozen_string_literal: true

require_relative 'fln_action'

module ColonialTwilight
  module Actions
    module FLN
      # Extort 4.3.1
      class Extort < FlnAction
        def initialize(space, mode)
          super(space, mode, 0)
        end

        # flip 1 Underground Guerrilla to Active
        # add 1 Resources to FLN track per space.
        def apply!(board)
          raise NotImplementedError
        end

        class << self
          def special?
            true
          end

          # any space with Population, Underground Guerrillas, and FLN Control
          # also Morocco/Tunisia if Independent and have Underground Guerrillas
          def applicable?(space)
            space.fln_underground.positive? &&
              (space.country? ? space.independent? : space.pop.positive? && space.fln_control?)
          end
        end
      end
    end
  end
end
