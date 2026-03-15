# frozen_string_literal: true

require_relative 'fln_action'

module ColonialTwilight
  module Actions
    module FLN
      # Subvert 4.3.2
      class Subvert < FlnAction
        def initialize(space, mode)
          super(space, mode, cost: 0)
          @second = nil
        end

        def validate!
          super
          return if @second.nil?

          p = (mode[:remove_police] || 0) + (@second.mode[:remove_police] || 0)
          t = (mode[:remove_troops] || 0) + (@second.mode[:remove_troops] || 0)
          raise "remove #{p} police + #{t} troops > 2" if p + t > 2
        end

        def subvert!(space2, mode2)
          raise 'subvert! called twice' unless @second.nil?
          raise 'cannot subvert! after replace algerian police' if mode.key?(:replace_police)
          raise 'cannot subvert! with replace algerian police' if mode2.key?(:replace_police)

          @second = Subvert.new(space2, mode2)
          validate!
        end

        # remove 2 Algerian cubes into Available, among selected spaces
        # or remove 1 Algerian Police and replace it with 1 Underground Guerrilla from Available.
        def apply!(board)
          raise NotImplementedError
        end

        class << self
          def special?
            true
          end

          # spaces with Underground Guerrillas and Algerian cubes.
          def applicable?(space)
            space.fln_underground.positive? && space.algerian_cubes.positive?
          end

          def available_modes(space)
            modes = {}
            if space.algerian_police.positive?
              modes[:replace_police] = 1
              modes[:remove_police] = space.algerian_police > 1 ? 2 : 1
            end
            modes[:remove_troops] = space.algerian_troops > 1 ? 2 : 1 if space.algerian_troops.positive?
            modes
          end
        end
      end
    end
  end
end
