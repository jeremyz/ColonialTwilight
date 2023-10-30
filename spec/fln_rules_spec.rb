# frozen_string_literal: true

require './lib/colonial_twilight/fln_rules'
require './lib/colonial_twilight/board'
require './spec/mock_board'

class FLNRulesImpl
  include ColonialTwilight::FLNRules
end

describe ColonialTwilight::FLNRules do
  rules = FLNRulesImpl.new

  before do
    @board = ColonialTwilight::Board.new
  end

  describe 'Rally' do
    it 'collects spaces where operation can be conducted' do
      expect(rules.rally_spaces(@board).size).to eq(28)
    end

    it 'collects spaces where operation can be conducted' do
      @board.load :short
      # 25 sectors + 2 countries
      expect(rules.rally_spaces(@board).size).to eq(27)
    end

    it 'may_rally_in? sector' do
      a = Sector.new
      expect(rules.may_rally_in?(a)).to be true
    end

    it 'may_rally_in? in city not at support' do
      a = Sector.new({ name: 'city', support: false })
      expect(rules.may_rally_in?(a)).to be true
    end

    it 'may_rally_in? not in city at support' do
      a = Sector.new({ name: 'city', support: true })
      expect(rules.may_rally_in?(a)).to be false
    end

    it 'may_rally_in? in independent country' do
      a = Sector.new({ name: 'country', independent: true })
      expect(rules.may_rally_in?(a)).to be true
    end

    it 'may_rally_in? not in not independent country' do
      a = Sector.new({ name: 'country', independent: false })
      expect(rules.may_rally_in?(a)).to be false
    end

    it 'may place 1 guerrillas' do
      a = Sector.new({ pop: 3 })
      expect(rules.max_placable_guerrillas(a)).to eq(1)
    end

    it 'may place pop + base guerrillas' do
      a = Sector.new({ pop: 3, fln_bases: 2 })
      expect(rules.max_placable_guerrillas(a)).to eq(5)
    end
  end

  describe 'Agitate' do
    it 'collects spaces where operation can be conducted' do
      expect(rules.agitate_spaces(@board).size).to eq(0)
    end

    it 'collects spaces where operation can be conducted' do
      @board.load :short
      # 4 with bases + 1 in fln control : but only 1 without fln control
      expect(rules.agitate_spaces(@board).size).to eq(1)
    end

    it 'compute agitate cost terror and shift' do
      a = Sector.new(terror: 2)
      expect(rules.max_agitate_cost(a)).to eq(3)
    end

    it 'compute agitate terror' do
      a = Sector.new(terror: 1, oppose: true)
      expect(rules.max_agitate_cost(a)).to eq(1)
    end
  end

  describe 'Attack' do
    it 'collects spaces where operation can be conducted' do
      # 25 sectors + 3 cities
      expect(rules.attack_spaces(@board).size).to eq(0)
    end

    it 'collects spaces where operation can be conducted' do
      @board.load :short
      # 25 sectors + 2 countries
      expect(rules.attack_spaces(@board).size).to eq(7)
    end
  end

  describe 'Terror' do
    it 'collects spaces where operation can be conducted' do
      expect(rules.terror_spaces(@board).size).to eq(0)
    end

    it 'collects spaces where operation can be conducted' do
      # 6 sectors
      @board.load :short
      expect(rules.terror_spaces(@board).size).to eq(6)
    end
  end

  describe 'Extort' do
    it 'collects spaces where operation can be conducted' do
      expect(rules.extort_spaces(@board).size).to eq(0)
    end

    it 'collects spaces where operation can be conducted' do
      @board.load :short
      # 2 sectors
      expect(rules.extort_spaces(@board).size).to eq(2)
    end
  end

  describe 'Subvert' do
    it 'collects spaces where operation can be conducted' do
      expect(rules.subvert_spaces(@board).size).to eq(0)
    end

    it 'collects spaces where operation can be conducted' do
      @board.load :short
      # 4 sectors
      expect(rules.subvert_spaces(@board).size).to eq(4)
    end
  end

  describe 'Ambush' do
    it 'collects spaces where operation can be conducted' do
      # 25 sectors + 3 cities
      expect(rules.ambush_spaces(@board).size).to eq(0)
    end

    it 'collects spaces where operation can be conducted' do
      @board.load :short
      # 25 sectors + 2 countries
      expect(rules.ambush_spaces(@board).size).to eq(7)
    end
  end

  describe 'OAS' do
    it 'collects spaces where operation can be conducted' do
      # 14 sectors + 3 cities
      expect(rules.oas_spaces(@board).size).to eq(17)
    end

    it 'collects spaces where operation can be conducted' do
      @board.load :short
      # 11 sectors + 3 countries
      expect(rules.oas_spaces(@board).size).to eq(14)
    end
  end
end
