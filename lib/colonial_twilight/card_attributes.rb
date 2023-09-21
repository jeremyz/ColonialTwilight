#! /usr/bin/env ruby
# frozen_string_literal: true

# rubocop:disable Style/Documentation

module ColonialTwilight
  module CardAttributes
    MAX_CARD_NUM = 71
    SINGLE = 1
    FLN_MARKED = 2
    FLN_SPECIAL = 4
    FLN_CAPABILITY = 8
    FLN_MOMENTUM = 16
    GOV_CAPABILITY = 32
    GOV_MOMENTUM = 64
    DUAL_CAPABILITY = 128
    DUAL_MOMENTUM = 256

    class << self
      attr_reader :cards
    end

    @cards = {
      1 => ['Quadrillage', 0],
      2 => ['Balky Conscripts', 0 | FLN_MOMENTUM],
      3 => ['Leadership Snatch', 0 | FLN_MARKED],
      4 => ['Oil & Gas Discoveries', 0 | SINGLE],
      5 => ['Peace of the Brave', 0 | GOV_MOMENTUM],
      6 => ['Factionalism', 0],
      7 => ['5th Bureau', 0 | FLN_MARKED],
      8 => ['Cross-border air strike', 0 | FLN_MOMENTUM],
      9 => ['Beni-Oui-Oui', 0 | SINGLE | FLN_MARKED],
      10 => ['Moudjahidine', 0 | FLN_MARKED | FLN_MOMENTUM],
      11 => ['Bananes', 0 | FLN_MARKED | GOV_MOMENTUM],
      12 => ['Ventilos', 0 | FLN_MARKED | FLN_SPECIAL | GOV_MOMENTUM],
      13 => ['SAS', 0 | GOV_CAPABILITY],
      14 => ['Protest in Paris', 0 | SINGLE | FLN_MARKED],
      15 => ['Jean-Paul Sarte', 0],
      16 => ['NATO', 0],
      17 => ['Commandos', 0 | FLN_CAPABILITY],
      18 => ['Torture', 0 | SINGLE | FLN_MARKED | DUAL_CAPABILITY],
      19 => ['General Strike', 0 | FLN_MARKED],
      20 => ['Sauve qui peut', 0 | SINGLE | FLN_MARKED | FLN_SPECIAL],
      21 => ['UN Resolution', 0],
      22 => ['The Government of USA is Convinced...', 0 | FLN_MARKED],
      23 => ['Diplomatic Leanings', 0 | FLN_MARKED],
      24 => ['Economic Development', 0 | FLN_MARKED],
      25 => ['Purge', 0 | SINGLE],
      26 => ['Casbah', 0 | FLN_MARKED],
      27 => ['Covert Movement', 0 | FLN_CAPABILITY],
      28 => ['Atrocities and Reprisals', 0 | SINGLE | FLN_MARKED],
      29 => ['The Call Up', 0 | FLN_MOMENTUM],
      30 => ['Change in Tactics', 0 | SINGLE],
      31 => ['Intimidation', 0 | FLN_MARKED | GOV_MOMENTUM],
      32 => ['Teleb the Bomb-maker', 0 | FLN_CAPABILITY],
      33 => ['Overkill', 0 | FLN_MARKED | FLN_CAPABILITY],
      34 => ['Elections', 0 | FLN_MARKED],
      35 => ['Napalm', 0 | FLN_MARKED | GOV_CAPABILITY],
      36 => ['Assassination', 0 | FLN_MARKED],
      37 => ['Integration', 0],
      38 => ['French Economic Crisis', 0],
      39 => ['Retreat into Djebel', 0],
      40 => ['Strategic Movement', 0 | FLN_MOMENTUM],
      41 => ['Egypt', 0 | FLN_MARKED],
      42 => ['Czech Arms Deal', 0 | FLN_MARKED],
      43 => ['Refugees', 0 | FLN_MARKED],
      44 => ['Paranoia', 0 | GOV_MOMENTUM],
      45 => ['Challe Plan', 0 | GOV_MOMENTUM | FLN_MOMENTUM],
      46 => ['Moghazni', 0 | GOV_MOMENTUM],
      47 => ['Third Force', 0 | FLN_MARKED],
      48 => ['Ultras', 0 | FLN_MARKED],
      49 => ['Factional Plot', 0 | FLN_MARKED | FLN_SPECIAL],
      50 => ['Bleuite', 0],
      51 => ['Stripey Hole', 0 | FLN_MARKED | FLN_SPECIAL],
      52 => ['Cabinet Shuffle', 0 | SINGLE],
      53 => ['Population Control', 0 | FLN_MARKED | GOV_MOMENTUM],
      54 => ['Operation 744', 0 | SINGLE | FLN_MARKED | FLN_SPECIAL],
      55 => ['Development', 0 | FLN_MARKED],
      56 => ['Hardened Attitudes', 0 | SINGLE | FLN_MARKED | FLN_SPECIAL | DUAL_MOMENTUM],
      57 => ['Peace Talks', 0 | SINGLE | FLN_MARKED | DUAL_MOMENTUM],
      58 => ['Army in Waiting', 0],
      59 => ['Bandung Conference', 0 | FLN_MARKED],
      60 => ['Soummam Conference', 0 | FLN_MARKED],
      61 => ['Morocco and Tunisia Independent', 0 | SINGLE],
      62 => ['Suez Crisis', 0 | SINGLE],
      63 => ['OAS', 0 | SINGLE],
      64 => ['Mobilization', 0 | SINGLE],
      65 => ['Recall De Gaulle', 0 | SINGLE],
      66 => ['Coup d\'etat', 0 | SINGLE],
      67 => ['Propaganda!', 0 | SINGLE],
      68 => ['Propaganda!', 0 | SINGLE],
      69 => ['Propaganda!', 0 | SINGLE],
      70 => ['Propaganda!', 0 | SINGLE],
      71 => ['Propaganda!', 0 | SINGLE]
    }
  end
end
