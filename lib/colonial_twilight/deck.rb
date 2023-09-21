#! /usr/bin/env ruby
# frozen_string_literal: true

# rubocop:disable Style/Documentation

require 'colonial_twilight/card_attributes'
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
      (@attributes & SINGLE).zero?
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
      # FIXME: todo
      false
    end

    def fln_effectiveness
      # FIXME: todo
      0
    end

    def fln_playable?
      # reduce GOV support or resources or commitment
      # shift France Track toward F
      # place FLN base or increase FLN resources
      false
    end

    def inspect
      s = @num < 10 ? ' ' : ''
      t = title + ' ' * (38 - title.size)
      s += "#{@num} - #{single? ? 'Single' : 'Dual  '} : #{t} : #{_capability} : #{_momentum}"
      s
    end

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
    end

    def pull(num)
      @card.set(num)
    end
  end
  # 1.upto(71) { |n| puts Deck.new.pull(n).inspect }
end
