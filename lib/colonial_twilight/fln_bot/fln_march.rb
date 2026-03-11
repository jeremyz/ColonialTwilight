# frozen_string_literal: true

module ColonialTwilight
  module FLNBotMarch
    def march
      return false if event_playable? && event_more_effective_than_terror?

      # FIXME
    end
  end
end
