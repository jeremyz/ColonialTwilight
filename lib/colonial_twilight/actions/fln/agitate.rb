# frozen_string_literal: true

require_relative 'fln_action'
require_relative 'rally'

module ColonialTwilight
  module Actions
    module FLN
      # Agitate 3.3.1
      class Agitate < FlnAction
        # 1 resources per Terror marker, then 1 resource for the level shift
        def initialize(space, mode)
          super(space, mode, cost: (mode[:remove_terror] || 0) + (mode[:shift_oppose] || 0))
        end

        def validate!
          super
          raise 'select at least 1 mode' unless mode.keys.size.positive?

          return if space.terror.zero? || (mode.key?(:remove_terror) && mode[:remove_terror] == space.terror)

          raise 'remove Terror marker first' if mode.key?(:shift_oppose)
        end

        # remove Terror first, then shift 1 level toward Oppose
        def apply!(board)
          raise NotImplementedError
        end

        class << self
          def op?
            true
          end

          # with Base and or Control && terror or shift to oppose possible
          def applicable?(space)
            Rally.applicable?(space) &&
              (space.fln_bases.positive? || space.fln_control?) && (space.terror.positive? || !space.oppose?)
          end

          def available_modes(space)
            modes = {}
            modes[:remove_terror] = space.terror if space.terror.positive?
            modes[:shift_oppose] = 1 unless space.oppose?
            modes
          end
        end
      end
    end
  end
end
