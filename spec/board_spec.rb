# frozen_string_literal: true

require './lib/colonial_twilight/board'

def compute(board)
  vals = [0] * 11
  board.spaces.each do |s|
    vals[0] += 1 if s.alignment == :support
    vals[1] += 1 if s.alignment == :oppose
    vals[2] += 1 if s.control == :GOV
    vals[3] += 1 if s.control == :FLN
    unless s.country?
      vals[4] += s.french_troops
      vals[5] += s.french_police
      vals[6] += s.algerian_troops
      vals[7] += s.algerian_police
      vals[8] += s.gov_bases
    end
    vals[9] += s.fln_underground
    vals[10] += s.fln_bases
  end
  vals
end

describe ColonialTwilight::Board do

  describe 'board setup' do
    board = ColonialTwilight::Board.new
    it 'has spaces' do expect(board.spaces.size).to eq(30) end
    it 'has sectors' do expect(board.sectors.size).to eq(28) end
    it 'has country sectors' do expect(board.spaces.select(&:country?).size).to eq(2) end
    it 'has coastal sectors' do expect(board.spaces.select(&:coastal?).size).to eq(14) end
    it 'has border sectors' do expect(board.spaces.select(&:border?).size).to eq(9) end
    it 'has mountain sectors' do expect(board.spaces.select(&:mountain?).size).to eq(21) end
    it 'has no mountain sectors' do expect(board.spaces.reject(&:mountain?).size).to eq(9) end
    it 'has city sectors' do expect(board.spaces.select(&:city?).size).to eq(3) end
    it 'has 0 pop sectors' do expect(board.spaces.select { |s| s.pop == 0 }.size).to eq(11) end
    it 'has 1 pop sectors' do expect(board.spaces.select { |s| s.pop == 1 }.size).to eq(9) end
    it 'has 2 pop sectors' do expect(board.spaces.select { |s| s.pop == 2 }.size).to eq(9) end
    it 'has 3 pop sectors' do expect(board.spaces.select { |s| s.pop == 3 }.size).to eq(1) end
  end

  describe 'short scenario setup' do
    board = ColonialTwilight::Board.new
    board.load :short
    it 'has 0 pop sectors' do expect(board.spaces.select { |s| s.pop == 0 }.size).to eq(14) end
    it 'has 1 pop sectors' do expect(board.spaces.select { |s| s.pop == 1 }.size).to eq(6) end
    it 'countries are independent' do expect(board.spaces.select(&:country?).select(&:independent?).size).to eq(2) end
    vals = compute board
    it 'total support' do expect(vals[0]).to eq(3) end
    it 'total opposition' do expect(vals[1]).to eq(7) end
    it 'total GOV control' do expect(vals[2]).to eq(16) end
    it 'total FLN control' do expect(vals[3]).to eq(3) end
    it 'total french troops' do expect(vals[4]).to eq(9) end
    it 'total french police' do expect(vals[5]).to eq(17) end
    it 'total algerian troops' do expect(vals[6]).to eq(3) end
    it 'total algerian police' do expect(vals[7]).to eq(7) end
    it 'total GOV bases' do expect(vals[8]).to eq(4) end
    it 'total FLN undergound' do expect(vals[9]).to eq(17) end
    it 'total FLN bases' do expect(vals[10]).to eq(8) end
    it 'oppositon + bases' do expect(board.opposition_bases).to eq(19) end
    it 'support + commitment' do expect(board.support_commitment).to eq (22) end
  end
end
