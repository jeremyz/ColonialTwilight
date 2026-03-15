# frozen_string_literal: true

module ColonialTwilight
  module Actions
    class GameAction
      def initialize(faction:, space:, cost: 0, mode: nil)
        @data = {
          faction: faction,
          space: space,
          cost: cost,
          mode: mode
        }
        validate!
      end

      def faction
        @data[:faction]
      end

      def space
        @data[:space]
      end

      def cost
        @data[:cost]
      end

      def mode
        @data[:mode]
      end

      def to_h
        @data.merge(type: self.class.name.split('::')[-1])
      end

      def validate!
        raise "not applicable to #{@data[:space]}" unless self.class.applicable?(@data[:space])

        available = self.class.available_modes(@data[:space])
        @data[:mode].each do |key, value|
          raise "mode: #{key} is not available" unless available.key?(key)

          max_allowed = available[key]
          raise "value: #{key} set to #{value}, max is #{max_allowed}" if value > max_allowed
        end
      end

      def apply!
        raise NotImplementedError
      end

      def revert!
        raise NotImplementedError
      end

      class << self
        def op?
          false
        end

        def special?
          false
        end

        def applicable?(space)
          raise NotImplementedError
        end

        def available_modes(_space)
          nil
        end

        def possible_spaces(board)
          board.search(&method(:applicable?))
        end
      end
    end
  end
end
