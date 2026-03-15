# frozen_string_literal: true

require_relative 'fln_action'

module ColonialTwilight
  module Actions
    module FLN
      # March 3.3.2
      class March < FlnAction
        def initialize(space, mode)
          super(space, mode, cost: 1)
        end

        def cost
          # Cost is 1 Resource per destination space moved into
          mode.keys.size
        end

        def validate!
          super
          raise 'select at least 1 destination' if mode.empty?

          total_moved = mode.values.sum
          raise "total moved #{total_moved} exceeds available #{space.guerrillas}" if total_moved > space.guerrillas
        end

        # move any number of Guerrillas to adjacent spaces as a group
        def apply!(board)
          raise NotImplementedError
        end

        class << self
          def op?
            true
          end

          # any space with FLN cubes
          def applicable?(space)
            space.guerrillas.positive?
          end

          def available_modes(space)
            space.adjacents.to_h { |idx| [idx, space.guerrillas] }
          end

          # the group must stop if moving across a Wilaya border or an International border
          def must_stop?(space_from, space_to)
            space_from.wilaya != space_to.wilaya || space_from.country? || space_to.country?
          end

          # if destination is at Support: activate group if moved FLN + Gov cubes > 3
          # when crossing International border: activate group if moved FLN + Gov cubes + Border level > 3
          def must_activate?(board, space_from, space_to, num = 1)
            international = space_from.country? || space_to.country?
            (international || space_to.support?) &&
              (num + space_to.gov_cubes + (international ? board.border_zone_track : 0)) > 3
          end
        end
      end
    end
  end
end
