# frozen_string_literal: true

require_relative 'fln_action'
require_relative 'agitate'

module ColonialTwilight
  module Actions
    module FLN
      # Rally 3.3.1
      class Rally < FlnAction
        def initialize(space, mode)
          super(space, mode, cost: 1)
          @agitate = nil
        end

        def cost
          super + (@agitate.nil? ? 0 : @agitate.cost)
        end

        def validate!
          super
          raise 'select 1 mode' if mode.keys.size != 1
          raise 'flip all Guerrillas' if mode.key?(:underground) && mode[:underground] != space.fln_active
        end

        # France track: shift 1 level toward "F"
        # in space place 1 underground Guerrilla, or replace 2 Guerrillas with 1 Base
        # or in space with FLN Base: add underground Guerrillas equal to population + Bases,
        # or flip all Guerrillas underground
        def apply!(board)
          raise NotImplementedError
        end

        def agitate!(mode)
          raise 'agitate! called twice' unless @agitate.nil?

          @agitate = Agitate.new(@data[:space], mode)
          self
        end

        class << self
          def op?
            true
          end

          # Sectors, Cities not at Support, Independent Countries, France track
          def applicable?(space)
            return space.name == 'France track' && !space.max? if space.track?

            space.sector? || (space.city? && !space.support?) || (space.country? && space.independent?)
          end

          def available_modes(space)
            modes = { place_guerilla: 1 }
            modes[:place_base] = 1 if space.guerrillas > 1 && space.bases < space.max_bases
            unless space.fln_bases.zero?
              modes[:place_guerilla] = space.fln_bases + space.pop
              modes[:underground] = space.fln_active if space.fln_active.positive?
            end
            modes
          end
        end
      end
    end
  end
end
