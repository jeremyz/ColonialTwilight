# frozen_string_literal: true

require_relative 'fln_action'

module ColonialTwilight
  module Actions
    module FLN
      # OAS 5.3.1
      class Oas < FlnAction
        def initialize(space, mode)
          super(space, mode, cost: 0)
        end

        # add 1 Terror, set to Neutral
        # GOV lose Commitment equal to Population, FLN lose Resources equal to twice Population.
        def apply!(board)
          raise NotImplementedError
        end

        class << self
          def special?
            true
          end

          # 1 populated space with no Terror not Country.
          def applicable?(space)
            !space.country? && space.pop.positive? && space.terror.zero?
          end
        end
      end
    end
  end
end
