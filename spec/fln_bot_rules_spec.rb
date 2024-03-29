# frozen_string_literal: true

require './lib/colonial_twilight/fln_rules'
require './lib/colonial_twilight/fln_bot_rules'
require './spec/mock_board'

class FLNRulesImpl
  include ColonialTwilight::FLNRules
  include ColonialTwilight::FLNBotRules
  attr_reader :board
  attr_writer :debug, :limited_op_only, :first_eligible, :will_be_next_first_eligible

  def initialize
    @debug = 0
    @board = Board.new
    @limited_op_only = true
    @first_eligible = true
    @will_be_next_first_eligible = true
  end

  def set(hash = {})
    board.sector.data = hash
    board.sector
  end

  def limited_op_only?
    @limited_op_only
  end

  def d6
    3
  end

  def first_eligible?
    @first_eligible
  end

  def will_be_next_first_eligible?
    @will_be_next_first_eligible
  end
end

describe ColonialTwilight::FLNBotRules do
  before do
    @rules = FLNRulesImpl.new
    @board = @rules.board
  end

  describe 'Debug' do
    it 'level 1' do
      @rules.debug = 1
      expect { @rules.dbg('msg', true) }.to output("  msg\n").to_stdout
    end

    it 'level 2' do
      @rules.debug = 2
      expect { @rules.dbg('msg', false) }.to output("  msg : NO\n").to_stdout
    end
  end

  describe 'Pass' do
    it 'pass? no resources' do
      expect(@rules.pass?).to be true
    end

    it 'pass? no resources but not op only' do
      @rules.limited_op_only = false
      expect(@rules.pass?).to be false
    end

    it 'pass? has resources' do
      @rules.board.fln_resources = 15
      expect(@rules.pass?).to be false
    end
  end

  describe 'Terror' do
    it 'terror1? 1 pop 2 underground' do
      @rules.set(pop: 1, fln_bases: 1, fln_underground: 2)
      expect(@rules.terror1?).to be true
    end

    it 'terror1? 1 pop 1 underground' do
      @rules.set(pop: 1, fln_bases: 1, fln_underground: 1)
      expect(@rules.terror1?).to be false
    end

    it 'terror1? 0 pop 1 underground' do
      @rules.set(pop: 0, fln_bases: 1, fln_underground: 1)
      expect(@rules.terror1?).to be true
    end

    it 'terror1? 0 pop 0 underground' do
      @rules.set(pop: 0, fln_bases: 1, fln_underground: 0)
      expect(@rules.terror1?).to be false
    end

    it 'terror2?' do
      expect(@rules.terror2?).to be false
    end

    it 'terror2? true' do
      @rules.first_eligible = false
      expect(@rules.terror2?).to be true
    end

    it 'terror2? true' do
      @rules.first_eligible = false
      @rules.will_be_next_first_eligible = false
      expect(@rules.terror2?).to be false
    end
  end

  describe 'Rally' do
    it 'rally1? false' do
      expect(@rules.rally1?).to be false
    end

    it 'rally1? may rally_1' do
      @rules.set(fln_active: 1, fln_underground: 2)
      expect(@rules.rally1?).to be true
    end

    it 'rally1? may rally_2' do
      @rules.set(fln_active: 2, fln_underground: 2)
      expect(@rules.rally1?).to be true
    end

    it 'rally1? may rally_1 but no bases' do
      @rules.set(fln_active: 1, fln_underground: 2)
      @board.available_fln_bases = 0
      expect(@rules.rally1?).to be false
    end

    it 'rally1? may rally_2 but no bases' do
      @rules.set(fln_active: 2, fln_underground: 2)
      @board.available_fln_bases = 0
      expect(@rules.rally1?).to be false
    end

    it 'rally2? enough fln at bases' do
      @rules.set(fln_bases: 2, fln_underground: 3)
      expect(@rules.rally2?).to be false
    end

    it 'rally2? false' do
      @rules.set(fln_bases: 2, fln_underground: 2)
      expect(@rules.rally2?).to be true
    end
  end

  describe 'Rally Specific' do
    it 'may_rally_1_in? not enough fln guerrillas' do
      a = Sector.new(fln_active: 1, fln_underground: 1)
      expect(@rules.may_rally_1_in?(a)).to be false
    end

    it 'may_rally_1_in? 3+ guerrillas' do
      a = Sector.new(fln_active: 1, fln_underground: 2)
      expect(@rules.may_rally_1_in?(a)).to be true
    end

    it 'may_rally_1_in? 3+ guerrillas no limited op' do
      a = Sector.new(fln_active: 1, fln_underground: 2)
      @rules.limited_op_only = false
      expect(@rules.may_rally_1_in?(a)).to be true
    end

    it 'may_rally_1_in? 3+ guerrillas but gov cubes' do
      a = Sector.new(fln_active: 1, fln_underground: 2, gov_cubes: 1)
      @rules.limited_op_only = false
      expect(@rules.may_rally_1_in?(a)).to be false
    end

    it 'may_rally_2_in? not enough fln guerrillas' do
      a = Sector.new(fln_active: 2, fln_underground: 1)
      expect(@rules.may_rally_2_in?(a)).to be false
    end

    it 'may_rally_2_in? 4+ guerrillas' do
      a = Sector.new(fln_active: 2, fln_underground: 2)
      expect(@rules.may_rally_2_in?(a)).to be true
    end

    it 'may_rally_3_in? no base' do
      a = Sector.new
      expect(@rules.may_rally_3_in?(a)).to be false
    end

    it 'may_rally_3_in? base and pop 0' do
      a = Sector.new(fln_bases: 1)
      expect(@rules.may_rally_3_in?(a)).to be true
    end

    it 'may_rally_3_in? base and pop 0 but has fln underground' do
      a = Sector.new(fln_bases: 1, fln_underground: 1)
      expect(@rules.may_rally_3_in?(a)).to be false
    end

    it 'may_rally_3_in? base and country but not independent' do
      a = Sector.new(fln_bases: 1, pop: 1, name: 'country', independent: false)
      expect(@rules.may_rally_3_in?(a)).to be false
    end

    it 'may_rally_3_in? base and country' do
      a = Sector.new(fln_bases: 1, pop: 1, name: 'country', independent: true)
      expect(@rules.may_rally_3_in?(a)).to be true
    end

    it 'may_rally_3_in? base and country but has fln underground' do
      a = Sector.new(fln_bases: 1, pop: 1, name: 'country', independent: true, fln_underground: 1)
      expect(@rules.may_rally_3_in?(a)).to be false
    end

    it 'may_rally_3_in? base and pop' do
      a = Sector.new(fln_bases: 1, pop: 1, fln_underground: 1)
      expect(@rules.may_rally_3_in?(a)).to be true
    end

    it 'may_rally_3_in? base and pop but too many fln underground ' do
      a = Sector.new(fln_bases: 1, pop: 1, fln_underground: 2)
      expect(@rules.may_rally_3_in?(a)).to be false
    end

    it 'rally_3_priority Algeria' do
      a = Sector.new(name: 'country')
      b = Sector.new
      expect(@rules.rally_3_priority([a, b])[0]).to be b
    end

    it 'rally_3_priority with GOV cubes' do
      a = Sector.new
      b = Sector.new(gov_cubes: 1)
      expect(@rules.rally_3_priority([a, b])[0]).to be b
    end

    it 'rally_3_priority pop 1+' do
      a = Sector.new(pop: 1)
      b = Sector.new(gov_cubes: 1)
      c = Sector.new(gov_cubes: 1, pop: 1)
      expect(@rules.rally_3_priority([a, b, c])[0]).to be c
    end

    it 'rally_3_priority least fln_underground' do
      a = Sector.new(pop: 1)
      b = Sector.new(gov_cubes: 1, pop: 1, fln_underground: 1)
      c = Sector.new(gov_cubes: 1, pop: 1)
      expect(@rules.rally_3_priority([a, b, c])[0]).to be c
    end

    it 'may_rally_5_in? city' do
      a = Sector.new(name: 'city', support: true)
      expect(@rules.may_rally_5_in?(a)).to be false
    end

    it 'may_rally_5_in? fln underground' do
      a = Sector.new(support: true, fln_underground: 1)
      expect(@rules.may_rally_5_in?(a)).to be false
    end

    it 'may_rally_5_in? no support' do
      a = Sector.new(support: false)
      expect(@rules.may_rally_5_in?(a)).to be false
    end

    it 'may_rally_5_in? good' do
      a = Sector.new(support: true)
      expect(@rules.may_rally_5_in?(a)).to be true
    end

    it 'rally_5_priority most pop' do
      a = Sector.new(pop: 1)
      b = Sector.new(pop: 2)
      expect(@rules.rally_5_priority([a, b])[0]).to be b
    end

    it 'may_rally_6_in? pop 1' do
      a = Sector.new(pop: 1)
      expect(@rules.may_rally_6_in?(a, false)).to be false
    end

    it 'may_rally_6_in? pop 2+ but no base, no control after' do
      a = Sector.new(pop: 2, gov_cubes: 1)
      @board.available_fln_underground = 1
      expect(@rules.may_rally_6_in?(a, false)).to be false
    end

    it 'may_rally_6_in? pop 2+ and base' do
      a = Sector.new(pop: 2, gov_cubes: 6, fln_bases: 1)
      expect(@rules.may_rally_6_in?(a, false)).to be true
    end

    it 'may_rally_6_in? pop 2+ and control' do
      a = Sector.new(pop: 2, gov_cubes: 1, fln_active: 1)
      @board.available_fln_underground = 1
      expect(@rules.may_rally_6_in?(a, false)).to be true
    end

    it 'may_rally_6_in? pop 2+ and control but oppose' do
      a = Sector.new(pop: 2, gov_cubes: 1, fln_active: 1, oppose: true)
      @board.available_fln_underground = 1
      expect(@rules.may_rally_6_in?(a, false)).to be false
    end

    it 'may_rally_6_in? pop 2+ and control but oppose but terror' do
      a = Sector.new(pop: 2, gov_cubes: 1, fln_active: 1, oppose: true, terror: 1)
      @board.available_fln_underground = 1
      expect(@rules.may_rally_6_in?(a, false)).to be true
    end

    it 'rally_6_priority population' do
      a = Sector.new(pop: 1)
      b = Sector.new(pop: 2)
      expect(@rules.rally_6_priority([a, b])[0]).to be b
    end

    it 'rally_6_priority min terror' do
      a = Sector.new(pop: 1, terror: 2)
      b = Sector.new(pop: 2, terror: 2)
      c = Sector.new(pop: 2, terror: 1)
      expect(@rules.rally_6_priority([a, b, c])[0]).to be c
    end

    it 'rally_6_priority support' do
      a = Sector.new(pop: 2, terror: 1, support: false)
      b = Sector.new(pop: 2, terror: 2, support: true)
      c = Sector.new(pop: 2, terror: 1, support: true)
      expect(@rules.rally_6_priority([a, b, c])[0]).to be c
    end

    it 'may_rally_7_in?' do
      a = Sector.new
      expect(@rules.may_rally_7_in?(a)).to be true
    end

    it 'may_rally_7_in? not in city at support' do
      a = Sector.new(name: 'city', support: true)
      expect(@rules.may_rally_7_in?(a)).to be false
    end

    it 'may_rally_7_in? not in not independent country' do
      a = Sector.new(name: 'country', independent: false)
      expect(@rules.may_rally_7_in?(a)).to be false
    end

    it 'rally_7_priority population' do
      a = Sector.new(pop: 1)
      b = Sector.new(pop: 1)
      c = Sector.new(pop: 2)
      expect(@rules.rally_7_priority([a, b, c])[0]).to be c
    end

    it 'rally_7_priority gain FLN control' do
      a = Sector.new(gov_cubes: 2)
      b = Sector.new(gov_cubes: 1, fln_active: 3)
      c = Sector.new(gov_cubes: 1, fln_active: 1)
      @board.available_fln_underground = 1
      expect(@rules.rally_7_priority([a, b, c])[0]).to be c
    end

    it 'rally_7_priority remove GOV control' do
      a = Sector.new(gov_cubes: 3)
      b = Sector.new(gov_cubes: 2)
      c = Sector.new(gov_cubes: 1)
      @board.available_fln_underground = 1
      expect(@rules.rally_7_priority([a, b, c])[0]).to be c
    end

    it 'rally_7_priority city?' do
      a = Sector.new
      b = Sector.new
      c = Sector.new(name: 'city')
      expect(@rules.rally_7_priority([a, b, c])[0]).to be c
    end

    it 'rally_7_priority least terror' do
      a = Sector.new
      b = Sector.new(name: 'city', terror: 2)
      c = Sector.new(name: 'city', terror: 1)
      expect(@rules.rally_7_priority([a, b, c])[0]).to be c
    end

    it 'may_rally_8_in? no fln guerrillas' do
      a = Sector.new
      expect(@rules.may_rally_8_in?(a)).to be false
    end

    it 'may_rally_8_in? fln guerrillas but base' do
      a = Sector.new(fln_active: 1, fln_bases: 1)
      expect(@rules.may_rally_8_in?(a)).to be false
    end

    it 'may_rally_8_in? fln guerrillas and 0 base' do
      a = Sector.new(fln_underground: 1)
      expect(@rules.may_rally_8_in?(a)).to be true
    end

    it 'rally_8_priority Algeria' do
      a = Sector.new(name: 'country')
      b = Sector.new
      expect(@rules.rally_8_priority([a, b])[0]).to be b
    end

    it 'rally_8_priority most guerrillas' do
      a = Sector.new
      b = Sector.new(fln_active: 1, fln_underground: 1)
      c = Sector.new(fln_active: 2, fln_underground: 1)
      expect(@rules.rally_8_priority([a, b, c])[0]).to be c
    end

    it 'rally_8_priority no cubes' do
      a = Sector.new
      b = Sector.new(fln_active: 1, fln_underground: 1, gov_cubes: 1)
      c = Sector.new(fln_active: 1, fln_underground: 1)
      expect(@rules.rally_8_priority([a, b, c])[0]).to be c
    end

    it 'may_rally_9_in? no control and no base' do
      a = Sector.new(terror: 2)
      expect(@rules.may_rally_9_in?(a)).to be false
    end

    it 'may_rally_9_in? has control but no terror and oppose' do
      a = Sector.new(fln_active: 1, oppose: true)
      expect(@rules.may_rally_9_in?(a)).to be false
    end

    it 'may_rally_9_in? has base but no terror and oppose' do
      a = Sector.new(fln_bases: 1, gov_cubes: 1, oppose: true)
      expect(@rules.may_rally_9_in?(a)).to be false
    end

    it 'may_rally_9_in? has control and terror' do
      a = Sector.new(fln_active: 1, terror: 1)
      expect(@rules.may_rally_9_in?(a)).to be true
    end

    it 'may_rally_9_in? has base and terror' do
      a = Sector.new(fln_bases: 1, gov_cubes: 1, terror: 1)
      expect(@rules.may_rally_9_in?(a)).to be true
    end

    it 'may_rally_9_in? has control and not oppose' do
      a = Sector.new(fln_active: 1, terror: 1)
      expect(@rules.may_rally_9_in?(a)).to be true
    end

    it 'may_rally_9_in? has base and not oppose' do
      a = Sector.new(fln_bases: 1, gov_cubes: 1, terror: 1)
      expect(@rules.may_rally_9_in?(a)).to be true
    end

    it 'rally_9_priority support rallied' do
      a = Sector.new(terror: 1, oppose: true)
      b = Sector.new(terror: 3, support: true)
      c = Sector.new(terror: 2, support: true)
      l = @rules.rally_9_priority([a, b, c], 3) { true }
      expect(l[0]).to be c
    end

    it 'rally_9_priority support not rallied' do
      a = Sector.new(terror: 1, oppose: true)
      b = Sector.new(terror: 2, support: true)
      c = Sector.new(terror: 1, support: true)
      l = @rules.rally_9_priority([a, b, c], 3) { false }
      expect(l[0]).to be c
    end

    it 'rally_9_priority neutral rallied' do
      a = Sector.new(terror: 1, oppose: true)
      b = Sector.new(terror: 3, neutral: true)
      c = Sector.new(terror: 2, neutral: true)
      l = @rules.rally_9_priority([a, b, c], 3) { true }
      expect(l[0]).to be c
    end

    it 'rally_9_priority neutral not rallied' do
      a = Sector.new(terror: 1, oppose: true)
      b = Sector.new(terror: 2, neutral: true)
      c = Sector.new(terror: 1, neutral: true)
      l = @rules.rally_9_priority([a, b, c], 3) { false }
      expect(l[0]).to be c
    end

    it 'rally_9_priority infinite resources rallied' do
      a = Sector.new(terror: 1, oppose: true)
      b = Sector.new(terror: 3, support: true)
      c = Sector.new(terror: 2, support: true)
      l = @rules.rally_9_priority([a, b, c], 0) { true }
      expect(l.size).to eq 2
    end

    it 'rally_9_priority infinite resources not rallied' do
      a = Sector.new(terror: 1, oppose: true)
      b = Sector.new(terror: 3, support: true)
      c = Sector.new(terror: 2, support: true)
      l = @rules.rally_9_priority([a, b, c], 0) { false }
      expect(l.size).to eq 2
    end

    it 'rally_9_priority infinite resources rallied' do
      a = Sector.new(terror: 1, oppose: true)
      b = Sector.new(terror: 3, support: true)
      c = Sector.new(terror: 2, support: true)
      l = @rules.rally_9_priority([a, b, c], 0) { true }
      expect(l.size).to eq 2
    end

    it 'rally_9_priority infinite resources not rallied' do
      a = Sector.new(terror: 1, oppose: true)
      b = Sector.new(terror: 3, support: true)
      c = Sector.new(terror: 2, support: true)
      l = @rules.rally_9_priority([a, b, c], 0) { false }
      expect(l.size).to eq 2
    end
  end

  describe 'Extort' do
    it 'may_extort_0_in?' do
      a = Sector.new
      expect(@rules.may_extort_0_in?(a)).to be false
    end

    it 'may_extort_0_in? pop' do
      a = Sector.new(pop: 1)
      expect(@rules.may_extort_0_in?(a)).to be false
    end

    it 'may_extort_0_in? pop and underground' do
      a = Sector.new(pop: 1, fln_underground: 1)
      expect(@rules.may_extort_0_in?(a)).to be true
    end

    it 'may_extort_0_in? pop and guerrillas but active' do
      a = Sector.new(pop: 1, fln_active: 1)
      expect(@rules.may_extort_0_in?(a)).to be false
    end

    it 'may_extort_0_in? pop and underground but no control' do
      a = Sector.new(pop: 1, fln_underground: 1, gov_cubes: 2)
      expect(@rules.may_extort_0_in?(a)).to be false
    end

    it 'may_extort_0_in? pop and underground but base' do
      a = Sector.new(pop: 1, fln_underground: 1, fln_bases: 1)
      expect(@rules.may_extort_0_in?(a)).to be false
    end

    it 'may_extort_0_in? pop, base and enough underground' do
      a = Sector.new(pop: 1, fln_underground: 2, fln_bases: 1, gov_cubes: 2)
      expect(@rules.may_extort_0_in?(a)).to be true
    end

    it 'extort_priority 2+' do
      a = Sector.new()
      b = Sector.new(fln_underground: 1)
      c = Sector.new(fln_underground: 2)
      expect(@rules.extort_priority([a, b, c])[0]).to be c
    end

    it 'extort_priority 3+ if fln bases and gov cubes' do
      a = Sector.new(fln_underground: 2, fln_bases: 1, gov_cubes: 1)
      b = Sector.new(fln_underground: 1, fln_bases: 1, gov_cubes: 1)
      c = Sector.new(fln_underground: 3, fln_bases: 1, gov_cubes: 1)
      expect(@rules.extort_priority([a, b, c])[0]).to be c
    end

    it 'extort_priority country' do
      a = Sector.new(fln_underground: 2, fln_bases: 1, gov_cubes: 1)
      b = Sector.new(fln_underground: 3, fln_bases: 1, gov_cubes: 1)
      c = Sector.new(name: 'country', fln_underground: 3, fln_bases: 1, gov_cubes: 1)
      expect(@rules.extort_priority([a, b, c])[0]).to be c
    end
  end

  describe 'Subvert' do
    it 'may_subvert_1_in?' do
      a = Sector.new
      expect(@rules.may_subvert_1_in?(a, 2)).to be false
    end

    it 'may_subvert_1_in?' do
      a = Sector.new(fln_underground: 1, algerian_police: 1)
      expect(@rules.may_subvert_1_in?(a, 2)).to be true
    end

    it 'may_subvert_1_in?' do
      a = Sector.new(fln_underground: 1, algerian_police: 3)
      expect(@rules.may_subvert_1_in?(a, 2)).to be false
    end

    it 'subvert_1_priority algerian police' do
      a = Sector.new(fln_underground: 1, algerian_police: 1)
      b = Sector.new(fln_underground: 1, algerian_police: 2)
      c = Sector.new(fln_underground: 1, algerian_police: 3)
      expect(@rules.subvert_1_priority([a, b, c])[0]).to be c
    end

    it 'may_subvert_2_in?' do
      a = Sector.new(fln_underground: 1)
      expect(@rules.may_subvert_2_in?(a)).to be false
    end

    it 'may_subvert_2_in?' do
      a = Sector.new(fln_underground: 1, algerian_police: 1)
      expect(@rules.may_subvert_2_in?(a)).to be true
    end
  end

  describe 'Terror' do
    it 'may_terror_1_in?' do
      a = Sector.new(pop: 1, fln_underground: 1, support: true)
      expect(@rules.may_terror_1_in?(a)).to be true
    end

    it 'may_terror_1_in? no pop' do
      a = Sector.new(fln_underground: 1, support: true)
      expect(@rules.may_terror_1_in?(a)).to be false
    end

    it 'may_terror_1_in? no support' do
      a = Sector.new(pop: 1, fln_underground: 1)
      expect(@rules.may_terror_1_in?(a)).to be false
    end

    it 'may_terror_1_in? no underground' do
      a = Sector.new(pop: 1, support: true)
      expect(@rules.may_terror_1_in?(a)).to be false
    end

    it 'may_terror_1_in? base and not enough underground' do
      a = Sector.new(pop: 1, fln_bases: 1, fln_underground: 1, support: true)
      expect(@rules.may_terror_1_in?(a)).to be false
    end

    it 'may_terror_1_in? base and enough underground' do
      a = Sector.new(pop: 1, fln_bases: 1, fln_underground: 2, support: true)
      expect(@rules.may_terror_1_in?(a)).to be true
    end

    it 'terror_1_priority most pop' do
      a = Sector.new(pop: 1)
      b = Sector.new(pop: 2)
      expect(@rules.terror_1_priority([a, b])[0]).to be b
    end

    it 'may_terro_2_in?' do
      a = Sector.new(pop: 1, fln_underground: 1, neutral: true, gov_bases: 1)
      expect(@rules.may_terror_2_in?(a)).to be true
    end

    it 'may_terro_2_in? default' do
      a = Sector.new(pop: 1, fln_underground: 1)
      expect(@rules.may_terror_2_in?(a)).to be false
    end

    it 'may_terro_2_in? is neutral' do
      a = Sector.new(pop: 1, fln_underground: 1, neutral: true)
      expect(@rules.may_terror_2_in?(a)).to be false
    end

    it 'may_terro_2_in? gov base' do
      a = Sector.new(pop: 1, fln_underground: 1, gov_bases: 1)
      expect(@rules.may_terror_2_in?(a)).to be false
    end

    it 'may_terro_2_in? neutral and gov base but terror' do
      a = Sector.new(pop: 1, fln_underground: 1, neutral: true, gov_bases: 1, terror: 1)
      expect(@rules.may_terror_2_in?(a)).to be false
    end

    it '_pacifiable no gov base' do
      a = Sector.new
      expect(@rules._pacifiable(a, false)).to be false
    end

    it '_pacifiable not country' do
      a = Sector.new(name: 'country', gov_bases: 1)
      expect(@rules._pacifiable(a, false)).to be false
    end

    it '_pacifiable not country and gov base' do
      a = Sector.new(gov_bases: 1)
      expect(@rules._pacifiable(a, false)).to be true
    end

    it '_pacifiable de Gaule country' do
      a = Sector.new(name: 'country', troops: 1, police: 1)
      expect(@rules._pacifiable(a, true)).to be false
    end

    it '_pacifiable de Gaule sector and troops and police and gov control' do
      a = Sector.new(troops: 1, french_police: 1)
      expect(@rules._pacifiable(a, true)).to be true
    end

    it '_pacifiable de Gaule no troops' do
      a = Sector.new(french_police: 1)
      expect(@rules._pacifiable(a, true)).to be false
    end

    it '_pacifiable de Gaule no police' do
      a = Sector.new(troops: 1)
      expect(@rules._pacifiable(a, true)).to be false
    end

    it '_pacifiable de Gaule no control' do
      a = Sector.new(troops: 1, french_police: 1, fln_underground: 2)
      expect(@rules._pacifiable(a, true)).to be false
    end
  end

  describe 'Attack' do
    it 'may attack 1' do
      a = Sector.new(gov_cubes: 1, fln_underground: 2, fln_active: 4)
      expect(@rules.may_attack_1_in?(a)).to be true
    end

    it 'may attack 1 but no gov' do
      a = Sector.new(fln_underground: 2, fln_active: 4)
      expect(@rules.may_attack_1_in?(a)).to be false
    end

    it 'may attack 1 but not enough fln' do
      a = Sector.new(gov_cubes: 1, fln_underground: 2, fln_active: 3)
      expect(@rules.may_attack_1_in?(a)).to be false
    end

    it 'may attack 1 but fln base' do
      a = Sector.new(gov_cubes: 1, fln_underground: 2, fln_active: 4, fln_bases: 1)
      expect(@rules.may_attack_1_in?(a)).to be false
    end

    it 'may attack 2' do
      a = Sector.new(gov_cubes: 1, fln_underground: 2, fln_active: 2)
      expect(@rules.may_attack_2_in?(a)).to be true
    end

    it 'may attack 2 but no gov' do
      a = Sector.new(fln_underground: 2, fln_active: 2)
      expect(@rules.may_attack_2_in?(a)).to be false
    end

    it 'may attack 2 but not enough fln' do
      a = Sector.new(gov_cubes: 1, fln_underground: 2, fln_active: 1)
      expect(@rules.may_attack_2_in?(a)).to be false
    end

    it 'may attack 2 but fln base' do
      a = Sector.new(gov_cubes: 1, fln_underground: 2, fln_active: 2, fln_bases: 1)
      expect(@rules.may_attack_2_in?(a)).to be false
    end

    it 'may ambush 1 in' do
      a = Sector.new(gov_cubes: 1, fln_underground: 1)
      expect(@rules.may_ambush_1_in?(a)).to be true
    end

    it 'may ambush 1 in but no underground' do
      a = Sector.new(gov_cubes: 1, fln_active: 1)
      expect(@rules.may_ambush_1_in?(a)).to be false
    end

    it 'may ambush 1 in but bases' do
      a = Sector.new(gov_cubes: 1, fln_underground: 1, fln_bases: 1)
      expect(@rules.may_ambush_1_in?(a)).to be false
    end

    it 'may ambush 1 in bases and enough guerillas' do
      a = Sector.new(gov_cubes: 1, fln_underground: 1, fln_active: 1, fln_bases: 1)
      expect(@rules.may_ambush_1_in?(a)).to be true
    end

    it 'attack priority at bases' do
      a = Sector.new(gov_bases: 0)
      b = Sector.new(gov_bases: 1)
      c = Sector.new(gov_bases: 2)
      expect(@rules.attack_priority([a, b, c])[0]).to be c
    end

    it 'attack priority french troops' do
      a = Sector.new(gov_bases: 2, algerian_troops: 6)
      b = Sector.new(gov_bases: 3, french_troops: 1)
      c = Sector.new(gov_bases: 3, french_troops: 2)
      expect(@rules.attack_priority([a, b, c])[0]).to be c
    end

    it 'attack priority french police' do
      a = Sector.new(gov_bases: 1, french_troops: 3, algerian_police: 6)
      b = Sector.new(gov_bases: 3, french_troops: 1, french_police: 1)
      c = Sector.new(gov_bases: 2, french_troops: 2, french_police: 2)
      expect(@rules.attack_priority([a, b, c])[0]).to be c
    end

    it 'attack priority gov most pieces, gov base' do
      a = Sector.new(gov_bases: 2, french_troops: 2, french_police: 2)
      b = Sector.new(gov_bases: 2, french_troops: 2, french_police: 2)
      c = Sector.new(gov_bases: 3, french_troops: 2, french_police: 2)
      expect(@rules.attack_priority([a, b, c])[0]).to be c
    end

    it 'attack priority gov most pieces, french troops' do
      a = Sector.new(gov_bases: 2, french_troops: 2, french_police: 2)
      b = Sector.new(gov_bases: 2, french_troops: 2, french_police: 2)
      c = Sector.new(gov_bases: 2, french_troops: 3, french_police: 2)
      expect(@rules.attack_priority([a, b, c])[0]).to be c
    end

    it 'attack priority gov most pieces, french police' do
      a = Sector.new(gov_bases: 2, french_troops: 2, french_police: 2)
      b = Sector.new(gov_bases: 2, french_troops: 2, french_police: 2)
      c = Sector.new(gov_bases: 2, french_troops: 2, french_police: 3)
      expect(@rules.attack_priority([a, b, c])[0]).to be c
    end
  end

  describe '8.1.2 Procedure Guidelines' do
    it 'placeable_guerrillas?' do
      expect(@rules.placeable_guerrillas?).to be false
    end

    it 'placeable_guerrillas? available' do
      @board.available_fln_underground = 1
      expect(@rules.placeable_guerrillas?).to be true
    end

    it 'placeable_guerrillas? active on map' do
      @board.spaces << Sector.new(name: 'a', fln_active: 1)
      expect(@rules.placeable_guerrillas?).to be true
    end

    it 'placeable_guerrillas' do
      expect(@rules.placeable_guerrillas).to eq 0
    end

    it 'placeable_guerrillas available' do
      @board.available_fln_underground = 1
      expect(@rules.placeable_guerrillas).to eq 1
    end

    it 'placeable_guerrillas active on map' do
      @board.spaces << Sector.new(name: 'a', fln_active: 1)
      expect(@rules.placeable_guerrillas).to eq 1
    end

    it 'available_fln_bases?' do
      @board.available_fln_bases = 0
      expect(@rules.available_fln_bases?).to be false
    end

    it 'available_fln_bases?' do
      @board.available_fln_bases = 1
      expect(@rules.available_fln_bases?).to be true
    end

    it 'may_add_base_in?' do
      a = Sector.new(fln_active: 3)
      expect(@rules.may_add_base_in?(a)).to be true
    end

    it 'may_add_base_in? not enough fln' do
      a = Sector.new(fln_active: 2)
      expect(@rules.may_add_base_in?(a)).to be false
    end

    it 'may_add_base_in? but has base' do
      a = Sector.new(fln_bases: 1, fln_active: 3)
      expect(@rules.may_add_base_in?(a)).to be false
    end

    it 'may_add_base_in? country ' do
      a = Sector.new(name: 'country', fln_bases: 2, fln_active: 3)
      expect(@rules.may_add_base_in?(a)).to be true
    end

    it 'may_add_base_in? country but limit' do
      a = Sector.new(name: 'country', fln_bases: 3, fln_active: 3)
      expect(@rules.may_add_base_in?(a)).to be false
    end

    it 'max_placable_guerrillas_in? 1' do
      a = Sector.new(pop: 2)
      expect(@rules.max_placable_guerrillas_in?(a)).to eq(1)
    end

    it 'max_placable_guerrillas_in? pop + base' do
      a = Sector.new(pop: 2, fln_bases: 1)
      expect(@rules.max_placable_guerrillas_in?(a)).to eq(3)
    end

    it 'max_placable_guerrillas_in? max pop + 1' do
      a = Sector.new(pop: 2, fln_bases: 1, fln_active: 1, fln_underground: 1)
      expect(@rules.max_placable_guerrillas_in?(a)).to eq(1)
    end

    it 'place_guerrillas_in' do
      a = Sector.new(pop: 2, fln_bases: 1)
      @board.available_fln_underground = 1
      @board.spaces << Sector.new(name: 'a', fln_bases: 1, fln_active: 2, fln_underground: 1)
      h = @rules.place_guerrillas_in(a)
      expect(@rules.max_placable_guerrillas_in?(a)).to eq(3)
      expect(h[:available]).to eq(1)
      expect(h[@board.spaces[0]]).to eq(1)
    end

    it 'place_guerrillas_in' do
      a = Sector.new(pop: 2, fln_bases: 1)
      @board.available_fln_underground = 0
      h = @rules.place_guerrillas_in(a)
      expect(@rules.max_placable_guerrillas_in?(a)).to eq(3)
      expect(h[:available]).to be nil
      expect(h.empty?).to be true
    end

    it '_removable_guerrillas active' do
      a = Sector.new(fln_active: 2, fln_underground: 3)
      expect(@rules._removable_guerrillas(a)).to eq(2)
    end

    it '_removable_guerrillas leave 2 at support' do
      a = Sector.new(support: true, fln_active: 3)
      expect(@rules._removable_guerrillas(a)).to eq(1)
    end

    it '_removable guerrillas leave 2 at bases' do
      a = Sector.new(fln_bases: 1, fln_active: 3, fln_underground: 1)
      expect(@rules._removable_guerrillas(a)).to eq(2)
    end

    it 'place_guerrillas_priority support' do
      a = Sector.new(support: false)
      b = Sector.new(support: false)
      c = Sector.new(support: true)
      expect(@rules.place_guerrillas_priority([a, b, c])[0]).to be c
    end

    it 'place_guerrillas_priority support and fln_active' do
      a = Sector.new(support: false)
      b = Sector.new(support: true)
      c = Sector.new(support: true, fln_active: 1)
      expect(@rules.place_guerrillas_priority([a, b, c])[0]).to be c
    end

    it '_remove_guerrillas_priority none' do
      a = Sector.new
      b = Sector.new
      expect(@rules._remove_guerrillas_priority([a, b], {}).empty?).to be true
    end

    it '_remove_guerrillas_priority most guerrillas' do
      a = Sector.new(fln_active: 2, fln_underground: 1)
      b = Sector.new(fln_active: 1, fln_underground: 2)
      c = Sector.new(fln_active: 2, fln_underground: 2)
      d = Sector.new(fln_active: 3, fln_underground: 2)
      expect(@rules._remove_guerrillas_priority([a, b, c, d], { d => true })[0]).to be c
    end

    it 'pick guerrillas from most guerrillas' do
      @rules.board.spaces << Sector.new(fln_active: 2, fln_underground: 1)
      @rules.board.spaces << (b = Sector.new(fln_active: 2, fln_underground: 2))
      @rules.board.spaces << Sector.new(fln_active: 1, fln_underground: 2)
      expect(@rules.pick_guerrillas_from(@rules.board)).to be b
    end

    it 'remove_from all' do
      a = Sector.new(fln_active: 2, fln_underground: 1, fln_bases: 1)
      h = @rules.remove_from(a, 6)
      expect(h[:fln_underground]).to be 1
      expect(h[:fln_active]).to be 2
      expect(h[:fln_bases]).to be 1
    end

    it 'remove_from a few' do
      a = Sector.new(fln_active: 1, fln_underground: 1)
      h = @rules.remove_from(a, 2)
      expect(h[:fln_underground]).to be 1
      expect(h[:fln_active]).to be 1
      expect(h[:fln_bases]).to be 0
    end
  end
end
