# frozen_string_literal: true

require './lib/colonial_twilight/fln_bot_rules'
require './spec/mock_board'

class FLNRulesImpl
  include ColonialTwilight::FLNBotRules
  attr_reader :board
  attr_writer :limited_op_only, :first_eligible, :will_be_next_first_eligible

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
      @rules.set({ pop: 1, fln_bases: 1, fln_underground: 2 })
      expect(@rules.terror1?).to be true
    end

    it 'terror1? 1 pop 1 underground' do
      @rules.set({ pop: 1, fln_bases: 1, fln_underground: 1 })
      expect(@rules.terror1?).to be false
    end

    it 'terror1? 0 pop 1 underground' do
      @rules.set({ pop: 0, fln_bases: 1, fln_underground: 1 })
      expect(@rules.terror1?).to be true
    end

    it 'terror1? 0 pop 0 underground' do
      @rules.set({ pop: 0, fln_bases: 1, fln_underground: 0 })
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
      @rules.set({ fln_active: 1, fln_underground: 2 })
      expect(@rules.rally1?).to be true
    end

    it 'rally1? may rally_2' do
      @rules.set({ fln_active: 2, fln_underground: 2 })
      expect(@rules.rally1?).to be true
    end

    it 'rally1? may rally_1 but no bases' do
      @rules.set({ fln_active: 1, fln_underground: 2 })
      @board.available_fln_bases = 0
      expect(@rules.rally1?).to be false
    end

    it 'rally1? may rally_2 but no bases' do
      @rules.set({ fln_active: 2, fln_underground: 2 })
      @board.available_fln_bases = 0
      expect(@rules.rally1?).to be false
    end

    it 'rally2? enough fln at bases' do
      @rules.set({ fln_bases: 2, fln_underground: 3 })
      expect(@rules.rally2?).to be false
    end

    it 'rally2? false' do
      @rules.set({ fln_bases: 2, fln_underground: 2 })
      expect(@rules.rally2?).to be true
    end
  end

  describe 'Rally Specific' do
    it 'may_rally_1_in? not enough fln guerrillas' do
      a = Sector.new({ fln_active: 1, fln_underground: 1 })
      expect(@rules.may_rally_1_in?(a)).to be false
    end

    it 'may_rally_1_in? 3+ guerrillas' do
      a = Sector.new({ fln_active: 1, fln_underground: 2 })
      expect(@rules.may_rally_1_in?(a)).to be true
    end

    it 'may_rally_1_in? 3+ guerrillas no limited op' do
      a = Sector.new({ fln_active: 1, fln_underground: 2 })
      @rules.limited_op_only = false
      expect(@rules.may_rally_1_in?(a)).to be true
    end

    it 'may_rally_1_in? 3+ guerrillas but gov cubes' do
      a = Sector.new({ fln_active: 1, fln_underground: 2, gov_cubes: 1 })
      @rules.limited_op_only = false
      expect(@rules.may_rally_1_in?(a)).to be false
    end

    it 'may_rally_2_in? not enough fln guerrillas' do
      a = Sector.new({ fln_active: 2, fln_underground: 1 })
      expect(@rules.may_rally_2_in?(a)).to be false
    end

    it 'may_rally_2_in? 4+ guerrillas' do
      a = Sector.new({ fln_active: 2, fln_underground: 2 })
      expect(@rules.may_rally_2_in?(a)).to be true
    end

    it 'may_rally_3_in? no base' do
      a = Sector.new
      expect(@rules.may_rally_3_in?(a)).to be false
    end

    it 'may_rally_3_in? base and pop 0' do
      a = Sector.new({ fln_bases: 1 })
      expect(@rules.may_rally_3_in?(a)).to be true
    end

    it 'may_rally_3_in? base and pop 0 but has fln underground' do
      a = Sector.new({ fln_bases: 1, fln_underground: 1 })
      expect(@rules.may_rally_3_in?(a)).to be false
    end

    it 'may_rally_3_in? base and country but not independent' do
      a = Sector.new({ fln_bases: 1, pop: 1, name: 'country', independent: false })
      expect(@rules.may_rally_3_in?(a)).to be false
    end

    it 'may_rally_3_in? base and country' do
      a = Sector.new({ fln_bases: 1, pop: 1, name: 'country', independent: true })
      expect(@rules.may_rally_3_in?(a)).to be true
    end

    it 'may_rally_3_in? base and country but has fln underground' do
      a = Sector.new({ fln_bases: 1, pop: 1, name: 'country', independent: true, fln_underground: 1 })
      expect(@rules.may_rally_3_in?(a)).to be false
    end

    it 'may_rally_3_in? base and pop' do
      a = Sector.new({ fln_bases: 1, pop: 1, fln_underground: 1 })
      expect(@rules.may_rally_3_in?(a)).to be true
    end

    it 'may_rally_3_in? base and pop but too many fln underground ' do
      a = Sector.new({ fln_bases: 1, pop: 1, fln_underground: 2 })
      expect(@rules.may_rally_3_in?(a)).to be false
    end

    it 'rally_3_priority Algeria' do
      a = Sector.new
      b = Sector.new({ name: 'country' })
      expect(@rules.rally_3_priority([a, b])[0]).to be a
    end

    it 'rally_3_priority with GOV cubes' do
      a = Sector.new
      b = Sector.new({ gov_cubes: 1 })
      expect(@rules.rally_3_priority([a, b])[0]).to be b
    end

    it 'rally_3_priority pop 1+' do
      a = Sector.new({ pop: 1 })
      b = Sector.new({ gov_cubes: 1, pop: 1 })
      c = Sector.new({ gov_cubes: 1 })
      expect(@rules.rally_3_priority([a, b, c])[0]).to be b
    end

    it 'rally_3_priority least fln_underground' do
      a = Sector.new({ pop: 1 })
      b = Sector.new({ gov_cubes: 1, pop: 1 })
      c = Sector.new({ gov_cubes: 1, pop: 1, fln_underground: 1 })
      expect(@rules.rally_3_priority([a, b, c])[0]).to be b
    end

    it 'may_rally_5_in? city' do
      a = Sector.new({ name: 'city', support: true })
      expect(@rules.may_rally_5_in?(a)).to be false
    end

    it 'may_rally_5_in? fln underground' do
      a = Sector.new({ support: true, fln_underground: 1 })
      expect(@rules.may_rally_5_in?(a)).to be false
    end

    it 'may_rally_5_in? no support' do
      a = Sector.new({ support: false })
      expect(@rules.may_rally_5_in?(a)).to be false
    end

    it 'may_rally_5_in? good' do
      a = Sector.new({ support: true })
      expect(@rules.may_rally_5_in?(a)).to be true
    end

    it 'rally_5_priority most pop' do
      a = Sector.new({ pop: 1 })
      b = Sector.new({ pop: 2 })
      expect(@rules.rally_5_priority([a, b])[0]).to be b
    end

    it 'may_rally_6_in? pop 1' do
      a = Sector.new({ pop: 1 })
      expect(@rules.may_rally_6_in?(a, false)).to be false
    end

    it 'may_rally_6_in? pop 1+' do
      a = Sector.new({ pop: 2 })
      expect(@rules.may_rally_6_in?(a, false)).to be true
    end

    it 'rally_6_priority population' do
      a = Sector.new({ pop: 2 })
      b = Sector.new({ pop: 1 })
      expect(@rules.rally_6_priority([a, b])[0]).to be a
    end

    it 'rally_6_priority min terror' do
      a = Sector.new({ pop: 1, terror: 2 })
      b = Sector.new({ pop: 2, terror: 1 })
      c = Sector.new({ pop: 2, terror: 2 })
      expect(@rules.rally_6_priority([a, b, c])[0]).to be b
    end

    it 'rally_6_priority support' do
      a = Sector.new({ pop: 2, terror: 1, support: false })
      b = Sector.new({ pop: 2, terror: 1, support: true })
      c = Sector.new({ pop: 2, terror: 2, support: true })
      expect(@rules.rally_6_priority([a, b, c])[0]).to be b
    end

    it 'may_rally_7_in?' do
      a = Sector.new
      expect(@rules.may_rally_7_in?(a)).to be true
    end

    it 'may_rally_7_in? not in city at support' do
      a = Sector.new({ name: 'city', support: true })
      expect(@rules.may_rally_7_in?(a)).to be false
    end

    it 'may_rally_7_in? not in not independent country' do
      a = Sector.new({ name: 'country', independent: false })
      expect(@rules.may_rally_7_in?(a)).to be false
    end

    it 'rally_7_priority_after city?' do
      a = Sector.new({ name: 'city' })
      b = Sector.new
      expect(@rules.rally_7_priority_after([a, b])[0]).to be a
    end

    it 'rally_7_priority_after least terror' do
      a = Sector.new
      b = Sector.new({ name: 'city', terror: 1 })
      c = Sector.new({ name: 'city', terror: 2 })
      expect(@rules.rally_7_priority_after([a, b, c])[0]).to be b
    end

    it 'rally_7_priority population' do
      a = Sector.new({ pop: 2 })
      b = Sector.new({ pop: 1 })
      expect(@rules.rally_7_priority([a, b])[0]).to be a
    end

    it 'rally_7_priority population' do
      a = Sector.new({ pop: 2 })
      b = Sector.new({ pop: 1 })
      expect(@rules.rally_7_priority([a, b])[0]).to be a
    end

    it 'may_rally_8_in? no fln guerrillas' do
      a = Sector.new
      expect(@rules.may_rally_8_in?(a)).to be false
    end

    it 'may_rally_8_in? fln guerrillas but base' do
      a = Sector.new({ fln_active: 1, fln_bases: 1 })
      expect(@rules.may_rally_8_in?(a)).to be false
    end

    it 'may_rally_8_in? fln guerrillas and 0 base' do
      a = Sector.new({ fln_underground: 1 })
      expect(@rules.may_rally_8_in?(a)).to be true
    end

    it 'rally_8_priority Algeria' do
      a = Sector.new
      b = Sector.new({ name: 'country' })
      expect(@rules.rally_8_priority([a, b])[0]).to be a
    end

    it 'rally_8_priority most guerrillas' do
      a = Sector.new
      b = Sector.new({ fln_active: 2, fln_underground: 1 })
      c = Sector.new({ fln_active: 1, fln_underground: 1 })
      expect(@rules.rally_8_priority([a, b, c])[0]).to be b
    end

    it 'rally_8_priority no cubes' do
      a = Sector.new
      b = Sector.new({ fln_active: 1, fln_underground: 1 })
      c = Sector.new({ fln_active: 1, fln_underground: 1, gov_cubes: 1 })
      expect(@rules.rally_8_priority([a, b, c])[0]).to be b
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
      a = Sector.new({ fln_active: 3 })
      expect(@rules.may_add_base_in?(a)).to be true
    end

    it 'may_add_base_in? not enough fln' do
      a = Sector.new({ fln_active: 2 })
      expect(@rules.may_add_base_in?(a)).to be false
    end

    it 'may_add_base_in? but has base' do
      a = Sector.new({ fln_bases: 1, fln_active: 3 })
      expect(@rules.may_add_base_in?(a)).to be false
    end

    it 'may_add_base_in? country ' do
      a = Sector.new({ name: 'country', fln_bases: 2, fln_active: 3 })
      expect(@rules.may_add_base_in?(a)).to be true
    end

    it 'may_add_base_in? country but limit' do
      a = Sector.new({ name: 'country', fln_bases: 3, fln_active: 3 })
      expect(@rules.may_add_base_in?(a)).to be false
    end

    it 'max_placable_guerrillas_in? 1' do
      a = Sector.new({ pop: 2 })
      expect(@rules.max_placable_guerrillas_in?(a)).to eq(1)
    end

    it 'max_placable_guerrillas_in? pop + base' do
      a = Sector.new({ pop: 2, fln_bases: 1 })
      expect(@rules.max_placable_guerrillas_in?(a)).to eq(3)
    end

    it 'max_placable_guerrillas_in? max pop + 1' do
      a = Sector.new({ pop: 2, fln_bases: 1, fln_active: 1, fln_underground: 1 })
      expect(@rules.max_placable_guerrillas_in?(a)).to eq(1)
    end

    it 'removable_guerrillas active' do
      a = Sector.new({ fln_active: 2, fln_underground: 3 })
      expect(@rules.removable_guerrillas(a)).to eq(2)
    end

    it 'removable_guerrillas leave 2 at support' do
      a = Sector.new({ support: true, fln_active: 3 })
      expect(@rules.removable_guerrillas(a)).to eq(1)
    end

    it 'removable guerrillas leave 2 at bases' do
      a = Sector.new({ fln_bases: 1, fln_active: 3, fln_underground: 1 })
      expect(@rules.removable_guerrillas(a)).to eq(2)
    end

    it 'place_guerrillas support' do
      a = Sector.new({ support: false })
      b = Sector.new({ support: true })
      c = Sector.new({ support: false })
      expect(@rules.place_guerrillas([a, b, c])[0]).to be b
    end

    it 'place_guerrillas support and fln_active' do
      a = Sector.new({ support: false })
      b = Sector.new({ support: true, fln_active: 1 })
      c = Sector.new({ support: true })
      expect(@rules.place_guerrillas([a, b, c])[0]).to be b
    end

    it 'remove_guerrillas_priority none' do
      a = Sector.new
      b = Sector.new
      expect(@rules.remove_guerrillas_priority([a, b], {}).empty?).to be true
    end

    it 'remove_guerrillas_priority most guerrillas' do
      a = Sector.new({ fln_active: 2, fln_underground: 1 })
      b = Sector.new({ fln_active: 2, fln_underground: 2 })
      c = Sector.new({ fln_active: 1, fln_underground: 2 })
      d = Sector.new({ fln_active: 3, fln_underground: 2 })
      expect(@rules.remove_guerrillas_priority([a, b, c, d], { d => true })[0]).to be b
    end

    it 'remove_from all' do
      a = Sector.new({ fln_active: 2, fln_underground: 1, fln_bases: 1 })
      h = @rules.remove_from(a, 6)
      expect(h[:fln_underground]).to be 1
      expect(h[:fln_active]).to be 2
      expect(h[:fln_bases]).to be 1
    end

    it 'remove_from a few' do
      a = Sector.new({ fln_active: 1, fln_underground: 1 })
      h = @rules.remove_from(a, 2)
      expect(h[:fln_underground]).to be 1
      expect(h[:fln_active]).to be 1
      expect(h[:fln_bases]).to be 0
    end
  end
end