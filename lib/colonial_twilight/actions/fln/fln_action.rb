# frozen_string_literal: true

require_relative '../action'

module ColonialTwilight
  module Actions
    class FlnAction < GameAction
      def initialize(space, mode, cost: 1)
        super(faction: :FLN, space: space, mode: mode, cost: cost)
      end
    end
  end
end
