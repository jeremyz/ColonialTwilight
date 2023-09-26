# frozen_string_literal: true

require './lib/colonial_twilight/deck'

describe ColonialTwilight::Card do
  before do
    @deck = ColonialTwilight::Deck.new
  end

  describe 'Pull' do
    it 'raise exception' do
      @deck.pull(1)
      expect { @deck.pull(1) }.to raise_error(Exception)
    end
  end

  describe 'Propaganda' do
    s = [67, 68, 69, 70, 71]
    1.upto(71) do |n|
      it "is flags right #{n}" do expect(@deck.pull(n).propaganda?).to be s.include?(n) end
    end
  end

  describe 'Single or Dual' do
    s = [4, 9, 14, 18, 20, 25, 28, 30, 52, 54, 56, 57, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71]
    1.upto(71) do |n|
      it "is flags right #{n}" do expect(@deck.pull(n).single?).to be s.include?(n) end
    end
  end

  describe 'FLN capability' do
    s = [17, 27, 32, 33]
    1.upto(71) do |n|
      it "is flags right #{n}" do expect(@deck.pull(n).fln_capability?).to be s.include?(n) end
    end
  end

  describe 'GOV capability' do
    s = [13, 35]
    1.upto(71) do |n|
      it "is flags right #{n}" do expect(@deck.pull(n).gov_capability?).to be s.include?(n) end
    end
  end

  describe 'DUAL capability' do
    s = [18]
    1.upto(71) do |n|
      it "is flags right #{n}" do expect(@deck.pull(n).dual_capability?).to be s.include?(n) end
    end
  end

  describe 'any capability' do
    s = [13, 17, 18, 27, 32, 33, 35]
    1.upto(71) do |n|
      it "is flags right #{n}" do expect(@deck.pull(n).capability?).to be s.include?(n) end
    end
  end

  describe 'FLN momentum' do
    s = [2, 8, 10, 29, 40, 45]
    1.upto(71) do |n|
      it "is flags right #{n}" do expect(@deck.pull(n).fln_momentum?).to be s.include?(n) end
    end
  end

  describe 'GOV momentum' do
    s = [5, 11, 12, 31, 44, 45, 46, 53]
    1.upto(71) do |n|
      it "is flags right #{n}" do expect(@deck.pull(n).gov_momentum?).to be s.include?(n) end
    end
  end

  describe 'DUAL momentum' do
    s = [56, 57]
    1.upto(71) do |n|
      it "is flags right #{n}" do expect(@deck.pull(n).dual_momentum?).to be s.include?(n) end
    end
  end
end
