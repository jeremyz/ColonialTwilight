# frozen_string_literal: true

require './lib/colonial_twilight/fln_rules'
require './lib/colonial_twilight/board'

class FLNRulesImpl
  include ColonialTwilight::FLNRules
end

describe ColonialTwilight::FLNRules do
  rules = FLNRulesImpl.new
  describe 'Rally' do
    board = ColonialTwilight::Board.new
    # 25 sectors + 3 cities
    it 'collects spaces where operation can be conducted' do expect(rules.rally_spaces(board).size).to eq(28) end
  end

  describe 'Rally' do
    board = ColonialTwilight::Board.new
    board.load :short
    # 25 sectors + 2 countries
    it 'collects spaces where operation can be conducted' do expect(rules.rally_spaces(board).size).to eq(27) end
  end

  describe 'Attack' do
    board = ColonialTwilight::Board.new
    # 25 sectors + 3 cities
    it 'collects spaces where operation can be conducted' do expect(rules.attack_spaces(board).size).to eq(0) end
  end

  describe 'Attack' do
    board = ColonialTwilight::Board.new
    board.load :short
    # 25 sectors + 2 countries
    it 'collects spaces where operation can be conducted' do expect(rules.attack_spaces(board).size).to eq(7) end
  end

  describe 'Terror' do
    board = ColonialTwilight::Board.new
    it 'collects spaces where operation can be conducted' do expect(rules.terror_spaces(board).size).to eq(0) end
  end

  describe 'Terror' do
    board = ColonialTwilight::Board.new
    board.load :short
    # 6 sectors
    it 'collects spaces where operation can be conducted' do expect(rules.terror_spaces(board).size).to eq(6) end
  end

  describe 'Extort' do
    board = ColonialTwilight::Board.new
    it 'collects spaces where operation can be conducted' do expect(rules.extort_spaces(board).size).to eq(0) end
  end

  describe 'Extort' do
    board = ColonialTwilight::Board.new
    board.load :short
    # 2 sectors
    it 'collects spaces where operation can be conducted' do expect(rules.extort_spaces(board).size).to eq(2) end
  end

  describe 'Subvert' do
    board = ColonialTwilight::Board.new
    it 'collects spaces where operation can be conducted' do expect(rules.subvert_spaces(board).size).to eq(0) end
  end

  describe 'Subvert' do
    board = ColonialTwilight::Board.new
    board.load :short
    # 4 sectors
    it 'collects spaces where operation can be conducted' do expect(rules.subvert_spaces(board).size).to eq(4) end
  end

  describe 'Ambush' do
    board = ColonialTwilight::Board.new
    # 25 sectors + 3 cities
    it 'collects spaces where operation can be conducted' do expect(rules.ambush_spaces(board).size).to eq(0) end
  end

  describe 'Ambush' do
    board = ColonialTwilight::Board.new
    board.load :short
    # 25 sectors + 2 countries
    it 'collects spaces where operation can be conducted' do expect(rules.ambush_spaces(board).size).to eq(7) end
  end

  describe 'OAS' do
    board = ColonialTwilight::Board.new
    # 14 sectors + 3 cities
    it 'collects spaces where operation can be conducted' do expect(rules.oas_spaces(board).size).to eq(17) end
  end

  describe 'OAS' do
    board = ColonialTwilight::Board.new
    board.load :short
    # 11 sectors + 3 countries
    it 'collects spaces where operation can be conducted' do expect(rules.oas_spaces(board).size).to eq(14) end
  end
end
