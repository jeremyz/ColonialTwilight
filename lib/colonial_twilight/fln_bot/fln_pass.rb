# frozen_string_literal: true

module ColonialTwilight
  module FLNBotPass
    def pass
      apply_action @turn.pass(1)
    end
  end
end
