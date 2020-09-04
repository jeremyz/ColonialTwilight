#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

module ColonialTwilight

  CARD_SINGLE=1
  CARD_FLN_MARKED=2
  CARD_ALWAYS_PLAY=4

  class Card
    attr_reader :num, :title
    def initialize n, t, attr, a0=nil, a1=nil
      @num = n
      @title = t
      @attributes = attr
      @a0 = a0
      @a1 = a1
    end
    def dual?; @attributes & CARD_SINGLE == 0 end
    def single?; @attributes & CARD_SINGLE == CARD_SINGLE end
    def fln_marked?; @attributes & CARD_FLN_MARKED == CARD_FLN_MARKED end
    def always_play?; @attributes & CARD_ALWAYS_PLAY == CARD_ALWAYS_PLAY end
    def capability?; false end
    def fln_effective?; false end
    def fln_effectiveness; 0 end
    def fln_playable?
      # reduce GOV support or resources or commitment
      # shift France Track toward F
      # place FLN base or increase FLN resources
      false
    end
    def check
      # @attributes.each do |attr| raise "unknown attribute : #{attr}" if attr not in ATTRS end
      # puts single?
      # puts dual?
      # puts flnmarked?
      # puts alwaysplay?
    end
  end

  class CardAction
    def initialize t, c
      @txt = t
      @condition=c
    end
  end

  class Deck
    attr_reader :cards
    def initialize
      @cards = {}
      add_card 0, 'None', nil, nil
      add_card 1, 'Quadrillage', 0, CardAction.new('Place up to all French Police in Available in up to 3 spaces', {:what=>:french_police,:from=>:available})
    end

    def pull n; @cards[n > 0 ? 1 : 0] end # FIXME

    private

    def add_card num, title, attrs, action
      @cards[num] = Card.new num, title, attrs
      @cards[num].check
    end

  end

end

 # 'Balky Conscripts'
 # 'Leadership Snatch'
 # 'Oil & Gas Discoveries'
 # 'Peace of the Brave'
 # 'Factionalism'
 # '5th Bureau'
 # 'Cross-border air strike'
 # 'Beni-Oui-Oui'
 # 'Moudjahidine'
 # 'Bananes'
 # 'Ventilos'
 # 'SAS'
 # 'Protest in Paris'
 # 'Jean-Paul Sarte'
 # 'NATO'
 # 'Commandos'
 # 'Torture'
 # 'General Strike'
 # 'Sauve qui peut'
 # 'United Nations Resolution'
 # 'The Government of USA is Convinced...'
 # 'Diplomatic Leanings'
 # 'Economic Development'
 # 'Purge'
 # 'Casbah'
 # 'Covert Movement'
 # 'Atrocities and Reprisals'
 # 'The Call Up'
 # 'Change in Tactics'
 # 'Intimidation'
 # 'Teleb the Bomb-maker'
 # 'Overkill'
 # 'Elections'
 # 'Napalm'
 # 'Assassination'
 # 'Integration'
 # 'Economic Crisis in France'
 # 'Retreat into Djebel'
 # 'Strategic Movement'
 # 'Egypt'
 # 'Czech Arms Deal'
 # 'Refugees'
 # 'Paranoia'
 # 'Challe Plan'
 # 'Moghazni'
 # 'Third Force'
 # 'Ultras'
 # 'Factional Plot'
 # 'Bleuite'
 # 'Stripey Hole'
 # 'Cabinet Shuffle'
 # 'Population Control'
 # 'Operation 744'
 # 'Development'
 # 'Hardened Attitudes'
 # 'Peace Talks'
 # 'Army in Waiting'
 # 'Bandung Conference'
 # 'Soummam Conference'
 # 'Morocco and Tunisia Independent'
 # 'Suez Crisis'
 # 'OAS'
 # 'Mobilization'
 # 'Recall De Gaulle'
 # "Coup d'etat"
 # "Propaganda!"
 # "Propaganda!"
 # "Propaganda!"
 # "Propaganda!"
 # "Propaganda!"
