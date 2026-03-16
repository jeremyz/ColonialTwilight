# frozen_string_literal: true

require_relative 'fln_action'
require_relative 'ambush'

module ColonialTwilight
  module Actions
    module FLN
      # Attack 3.3.3
      class Attack < FlnAction
        def initialize(space)
          super(space, {}, 1)
          @ambush = nil
        end

        # can be combined with Ambush (replaces Attack procedure)
        def ambush!
          raise 'ambush! called twice' unless @ambush.nil?

          @ambush = Ambush.new(space)
          self
        end


        # def validate!
        #   super
        #   raise 'select conduct mode' unless mode.key?(:conduct)
        # end

        # Activate all Guerrillas in the space
        # Roll 1d6: if result is less than or equal to number of Guerrillas
        #   remove up to 2 Gov pieces (Police first, then Troops, then Base) into casualties
        # If result is a 1, add 1 underground Guerrillas
        # Attrition (not Ambush) : for each French piece removed : remove 1 FLN Guerrillas (alternate available / casualties)
        # -1 Commitment per French Base removed
        def apply!(board)
          raise NotImplementedError
        end

        class << self
          def op?
            true
          end

          # any space with FLN cubes and Gov pieces
          def applicable?(space)
            space.guerrillas.positive? && space.gov.positive?
          end

          # def available_modes(_space)
          #   { conduct: 1 }
          # end
        end
      end
    end
  end
end
