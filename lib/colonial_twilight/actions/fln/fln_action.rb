# frozen_string_literal: true

require_relative '../action'

module ColonialTwilight
  module Actions
    class FlnAction < GameAction
      def initialize(space, mode, cost)
        super(:FLN, space, mode, cost)
      end
    end
  end
end
