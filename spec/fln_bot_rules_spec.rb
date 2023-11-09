# frozen_string_literal: true

require './lib/colonial_twilight/fln_bot_rules'
require './spec/mock_board'

class FLNRulesImpl
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
      a = Sector.new
      b = Sector.new(name: 'country')
      expect(@rules.rally_3_priority([a, b])[0]).to be a
    end

    it 'rally_3_priority with GOV cubes' do
      a = Sector.new
      b = Sector.new(gov_cubes: 1)
      expect(@rules.rally_3_priority([a, b])[0]).to be b
    end

    it 'rally_3_priority pop 1+' do
      a = Sector.new(pop: 1)
      b = Sector.new(gov_cubes: 1, pop: 1)
      c = Sector.new(gov_cubes: 1)
      expect(@rules.rally_3_priority([a, b, c])[0]).to be b
    end

    it 'rally_3_priority least fln_underground' do
      a = Sector.new(pop: 1)
      b = Sector.new(gov_cubes: 1, pop: 1)
      c = Sector.new(gov_cubes: 1, pop: 1, fln_underground: 1)
      expect(@rules.rally_3_priority([a, b, c])[0]).to be b
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
      a = Sector.new(pop: 2)
      b = Sector.new(pop: 1)
      expect(@rules.rally_6_priority([a, b])[0]).to be a
    end

    it 'rally_6_priority min terror' do
      a = Sector.new(pop: 1, terror: 2)
      b = Sector.new(pop: 2, terror: 1)
      c = Sector.new(pop: 2, terror: 2)
      expect(@rules.rally_6_priority([a, b, c])[0]).to be b
    end

    it 'rally_6_priority support' do
      a = Sector.new(pop: 2, terror: 1, support: false)
      b = Sector.new(pop: 2, terror: 1, support: true)
      c = Sector.new(pop: 2, terror: 2, support: true)
      expect(@rules.rally_6_priority([a, b, c])[0]).to be b
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
      a = Sector.new(pop: 2)
      b = Sector.new(pop: 1)
      c = Sector.new(pop: 1)
      expect(@rules.rally_7_priority([a, b, c])[0]).to be a
    end

    it 'rally_7_priority gain FLN control' do
      a = Sector.new(gov_cubes: 2)
      b = Sector.new(gov_cubes: 1, fln_active: 1)
      c = Sector.new(gov_cubes: 1)
      @board.available_fln_underground = 1
      expect(@rules.rally_7_priority([a, b, c])[0]).to be b
    end

    it 'rally_7_priority remove GOV control' do
      a = Sector.new(gov_cubes: 3)
      b = Sector.new(gov_cubes: 1)
      c = Sector.new(gov_cubes: 2)
      @board.available_fln_underground = 1
      expect(@rules.rally_7_priority([a, b, c])[0]).to be b
    end

    it 'rally_7_priority city?' do
      a = Sector.new(name: 'city')
      b = Sector.new
      expect(@rules.rally_7_priority([a, b])[0]).to be a
    end

    it 'rally_7_priority least terror' do
      a = Sector.new
      b = Sector.new(name: 'city', terror: 1)
      c = Sector.new(name: 'city', terror: 2)
      expect(@rules.rally_7_priority([a, b, c])[0]).to be b
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
      a = Sector.new
      b = Sector.new(name: 'country')
      expect(@rules.rally_8_priority([a, b])[0]).to be a
    end

    it 'rally_8_priority most guerrillas' do
      a = Sector.new
      b = Sector.new(fln_active: 2, fln_underground: 1)
      c = Sector.new(fln_active: 1, fln_underground: 1)
      expect(@rules.rally_8_priority([a, b, c])[0]).to be b
    end

    it 'rally_8_priority no cubes' do
      a = Sector.new
      b = Sector.new(fln_active: 1, fln_underground: 1)
      c = Sector.new(fln_active: 1, fln_underground: 1, gov_cubes: 1)
      expect(@rules.rally_8_priority([a, b, c])[0]).to be b
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

    it 'rally_9_priority no cubes' do
      a = Sector.new(terror: 1, oppose: true)
      b = Sector.new(terror: 1, neutral: true)
      c = Sector.new(terror: 2, neutral: true)
      expect(@rules.rally_9_priority([a, b, c], 2)[0]).to be b
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
      a = Sector.new(fln_underground: 1)
      b = Sector.new(fln_underground: 2)
      c = Sector.new(fln_underground: 1)
      expect(@rules.extort_priority([a, b, c])[0]).to be b
    end

    it 'extort_priority 3+ if fln bases and gov cubes' do
      a = Sector.new(fln_underground: 2, fln_bases: 1, gov_cubes: 1)
      b = Sector.new(fln_underground: 3, fln_bases: 1, gov_cubes: 1)
      c = Sector.new(fln_underground: 2, fln_bases: 1, gov_cubes: 1)
      expect(@rules.extort_priority([a, b, c])[0]).to be b
    end

    it 'extort_priority country' do
      a = Sector.new(fln_underground: 2, fln_bases: 1, gov_cubes: 1)
      b = Sector.new(fln_underground: 3, fln_bases: 1, gov_cubes: 1, type: :country)
      c = Sector.new(fln_underground: 3, fln_bases: 1, gov_cubes: 1)
      expect(@rules.extort_priority([a, b, c])[0]).to be b
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
      b = Sector.new(fln_underground: 1, algerian_police: 3)
      c = Sector.new(fln_underground: 1, algerian_police: 2)
      expect(@rules.subvert_1_priority([a, b, c])[0]).to be b
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

  describe '8.1.2 Procedure Guidelines' do
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
      b = Sector.new(support: true)
      c = Sector.new(support: false)
      expect(@rules.place_guerrillas_priority([a, b, c])[0]).to be b
    end

    it 'place_guerrillas_priority support and fln_active' do
      a = Sector.new(support: false)
      b = Sector.new(support: true, fln_active: 1)
      c = Sector.new(support: true)
      expect(@rules.place_guerrillas_priority([a, b, c])[0]).to be b
    end

    it '_remove_guerrillas_priority none' do
      a = Sector.new
      b = Sector.new
      expect(@rules._remove_guerrillas_priority([a, b], {}).empty?).to be true
    end

    it '_remove_guerrillas_priority most guerrillas' do
      a = Sector.new(fln_active: 2, fln_underground: 1)
      b = Sector.new(fln_active: 2, fln_underground: 2)
      c = Sector.new(fln_active: 1, fln_underground: 2)
      d = Sector.new(fln_active: 3, fln_underground: 2)
      expect(@rules._remove_guerrillas_priority([a, b, c, d], { d => true })[0]).to be b
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
