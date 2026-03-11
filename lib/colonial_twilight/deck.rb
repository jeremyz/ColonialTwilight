# frozen_string_literal: true

require_relative 'deck/card_attributes'

module ColonialTwilight
  class Card
    include ColonialTwilight::CardAttributes

    attr_reader :num, :title

    def set(num)
      raise "card #{num} is out of range [1; #{MAX_CARD_NUM}]" if !num.positive? || num > MAX_CARD_NUM

      @num = num
      card = ColonialTwilight::CardAttributes.cards[num] || [nil, nil]
      @title = card[0]
      @attributes = card[1]
      self
    end

    def propaganda?
      @num >= 67
    end

    def dual?
      !single?
    end

    def single?
      (@attributes & SINGLE) == SINGLE
    end

    def fln_marked?
      (@attributes & FLN_MARKED) == FLN_MARKED
    end

    def special?
      (@attributes & FLN_SPECIAL) == FLN_SPECIAL
    end

    def capability?
      fln_capability? || gov_capability? || dual_capability?
    end

    def fln_capability?
      (@attributes & FLN_CAPABILITY) == FLN_CAPABILITY
    end

    def gov_capability?
      (@attributes & GOV_CAPABILITY) == GOV_CAPABILITY
    end

    def dual_capability?
      (@attributes & DUAL_CAPABILITY) == DUAL_CAPABILITY
    end

    def fln_momentum?
      (@attributes & FLN_MOMENTUM) == FLN_MOMENTUM
    end

    def gov_momentum?
      (@attributes & GOV_MOMENTUM) == GOV_MOMENTUM
    end

    def dual_momentum?
      (@attributes & DUAL_MOMENTUM) == DUAL_MOMENTUM
    end

    def fln_effective?
      fln_efficiency.positive?
    end

    def fln_efficiency
      # FIXME: called from Terror, how much it would reduce the Government victory margin
      # (support / resources / commitment)
      0
    end

    def fln_playable?
      # may_play_event && fln_effective?
      #   if fln_marked?      -> Yes
      #   or any_capability?  -> Yes
      #   or 1d6 1-4 && (
      #     reduce Govt support or resources or commitment
      #     or shift France Track toward F
      #     or place FLN base or increase FLN resources
      #   )                   -> Yes
      #
      # when playing Event : FLN always selects itself for a benefit first, then to inflict disadvantage on the Government.
      false
    end

    def inspect
      s = @num < 10 ? ' ' : ''
      t = title + ' ' * (38 - title.size)
      s += "#{@num} - #{single? ? 'Single' : 'Dual  '} : #{t} : #{_capability} : #{_momentum}"
      s
    end
    alias to_s inspect

    def _capability
      s = ''
      s += ' FLN-capability' if fln_capability?
      s += ' GOV-capability' if gov_capability?
      s += 'DUAL-capability' if dual_capability?
      s = ' ' * 15 if s.empty?
      s
    end

    def _momentum
      s = ''
      s += ' FLN-momentum  ' if fln_momentum?
      s += ' GOV-momentum  ' if gov_momentum?
      s += 'DUAL-momentum  ' if dual_momentum?
      s
    end
  end

  # class CardAction
  #   def initialize(txt, cond)
  #     @txt = txt
  #     @condition = cond
  #   end
  # end

  class Deck
    attr_reader :card

    def initialize
      @card = Card.new
      @played = []
    end

    def pull(num)
      raise "card #{num} already played" if @played.include? num

      @played << num
      @card.set(num)
    end
  end
  # 1.upto(71) { |n| puts Deck.new.pull(n).inspect }
end
