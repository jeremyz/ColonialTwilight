# frozen_string_literal: true

require_relative 'fln_action'

module ColonialTwilight
  module Actions
    module FLN
      # Terror 3.3.4
      class Terror < FlnAction
        def initialize(space, mode)
          super(space, mode, 1)
        end

        # flip 1 Underground Guerrilla to Active.
        # place 1 Terror marker if none (max 12 on the map), set to Neutral
        def apply!(board)
          raise NotImplementedError
        end

        class << self
          def op?
            true
          end

          # Populated not Resettled space with Underground Guerrillas.
          def applicable?(space)
            !space.country? && space.pop.positive? && space.fln_underground.positive? # && !space.resettled?
          end
        end
      end
    end
  end
end
