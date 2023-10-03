# frozen_string_literal: true

require './lib/colonial_twilight/fln_bot_rules'
require './lib/colonial_twilight/game'

class FLNRulesImpl
  include ColonialTwilight::FLNBotRules
  def initialize
    @debug = 0
    @board = nil
  end
  attr_writer :board

  def limited_op_only?
    true
  end

  def d6
    5
  end

  # def first_eligible?
  #   true
  # end
  #
  # def will_be_next_first_eligible?
  #   true
  # end
end

describe ColonialTwilight::FLNBotRules do

  rules = FLNRulesImpl.new
  before do
    @board = ColonialTwilight::Board.new
    @board.load :short
    rules.board = @board
  end

  describe 'Pass' do
    it 'pass? no' do
      expect(rules.pass?).to be false
    end

    it 'pass? no resources' do
      @board.shift_track :fln_resources, -15
      expect(rules.pass?).to be true
    end
  end

  describe 'Terror' do
    it 'terror1? no' do
      expect(rules.terror1?).to be false
    end

    it 'terror1? all bases are protected' do
      @board.by_name('Souk Ahras').add :fln_underground
      @board.by_name('Tizi Ouzou').add :fln_underground
      @board.by_name('Bougie').add :fln_underground
      @board.by_name('Orleansville').add :fln_underground
      expect(rules.terror1?).to be true
    end

    # it 'terror2? true' do
    #   expect(rules.terror2?).to be false
    # end
  end

  describe 'Rally' do

    it 'rally1? false' do
      expect(rules.rally1?).to be false
    end

    it 'rally1? may rally_1' do
      space = @board.by_name('Barika')
      space.add :fln_active, 2
      expect(rules.rally1?).to be true
    end

    it 'rally1? may rally_2' do
      space = @board.by_name('Barika')
      space.add :fln_active, 3
      expect(rules.rally1?).to be true
    end

    it 'rally2? enough fln at bases' do
      expect(rules.rally2?).to be true
    end

    it 'rally2? false' do
      @board.by_name('Bougie').add :fln_active, 1
      expect(rules.rally2?).to be false
    end

    it 'may_add_base_in?' do
      expect(@board.spaces.select(&rules.method(:may_add_base_in?)).size).to eq(0)
    end

    it 'may_add_base_in?' do
      @board.by_name('Batna').add :fln_active, 3
      expect(@board.spaces.select(&rules.method(:may_add_base_in?))[0].name).to eq('Batna')
    end

    it 'may_add_base_in?' do
      space = @board.by_name('Batna')
      space.add :fln_active, 6
      space.add :fln_base, 1
      expect(@board.spaces.select(&rules.method(:may_add_base_in?)).size).to eq(0)
    end

    it 'rally_1_in? not enough fln cubes' do
      space = @board.by_name('Barika')
      expect(rules.rally_1_in?(space)).to be false
    end

    it 'rally_1_in? enough fln cubes' do
      space = @board.by_name('Barika')
      space.add :fln_active, 2
      expect(rules.rally_1_in?(space)).to be true
    end

    it 'rally_2_in? not enough fln cubes' do
      space = @board.by_name('Barika')
      expect(rules.rally_2_in?(space)).to be false
    end

    it 'rally_2_in? enough fln cubes' do
      space = @board.by_name('Barika')
      space.add :fln_active, 3
      expect(rules.rally_2_in?(space)).to be true
    end

    it 'rally_3_in? no base' do
      space = @board.by_name('Batna')
      expect(rules.rally_3_in?(space)).to be false
    end

    it 'rally_3_in? base and 0 pop and 0 fln underground' do
      space = @board.by_name('Batna')
      space.add :fln_base, 1
      expect(rules.rally_3_in?(space)).to be true
    end

    it 'rally_3_in? base and 0 pop but fln underground' do
      space = @board.by_name('Batna')
      space.add :fln_base, 1
      space.add :fln_underground, 1
      expect(rules.rally_3_in?(space)).to be false
    end

    it 'rally_3_in? base and not enough fln underground' do
      space = @board.by_name('Bougie')
      expect(rules.rally_3_in?(space)).to be true
    end

    it 'rally_3_in? base but not enough fln underground' do
      space = @board.by_name('Bougie')
      space.add :fln_underground, 1
      expect(rules.rally_3_in?(space)).to be false
    end

    it 'rally_3_priority Algeria' do
      a = @board.by_name('Ain Oussera')
      b = @board.by_name('Morocco')
      b.add :fln_base, -2
      b.add :fln_underground, -4
      expect(rules.rally_3_priority([a, b]).name).to eq('Ain Oussera')
    end

    it 'rally_3_priority with GOV cubes' do
      a = @board.by_name('Mecheria')
      b = @board.by_name('Saida')
      expect(rules.rally_3_priority([a, b]).name).to eq('Mecheria')
    end

    it 'rally_3_priority pop 1+' do
      a = @board.by_name('Ain Oussera')
      b = @board.by_name('Sidi Aissa')
      expect(rules.rally_3_priority([a, b]).name).to eq('Ain Oussera')
    end

    it 'rally_3_priority least fln_underground' do
      a = @board.by_name('Tebessa')
      a.add :fln_underground, 1
      b = @board.by_name('Barika')
      expect(rules.rally_3_priority([a, b]).name).to eq('Barika')
    end

    it 'rally_5_in? city' do
      space = @board.by_name('Oran')
      expect(rules.rally_5_in?(space)).to be false
    end

    it 'rally_5_in? support but fln underground' do
      space = @board.by_name('Barika')
      space.shift :support
      expect(rules.rally_5_in?(space)).to be false
    end

    it 'rally_5_in? support and fln underground' do
      space = @board.by_name('Barika')
      space.shift :support
      space.add :fln_underground, -1
      expect(rules.rally_5_in?(space)).to be false
    end

    it 'rally_6_in? 2+ pop but no fln control' do
      space = @board.by_name('Medea')
      expect(rules.rally_6_in?(space)).to be false
    end

    it 'rally_6_in? 2+ pop and fln' do
      space = @board.by_name('Medea')
      space.add :fln_active, 3
      expect(rules.rally_6_in?(space)).to be true
    end

    it 'rally_8_in? no fln cubes' do
      space = @board.by_name('Tiaret')
      expect(rules.rally_8_in?(space)).to be false
    end

    it 'rally_8_in? fln cubes but base' do
      space = @board.by_name('Bougie')
      expect(rules.rally_8_in?(space)).to be false
    end

    it 'rally_8_in? fln cubes and 0 base' do
      space = @board.by_name('Barika')
      expect(rules.rally_8_in?(space)).to be true
    end
  end

  describe '8.1.2 Procedure Guidelines' do
    it 'place_in' do
      expect(rules.place_in(@board.spaces).city?).to be true
    end

    it 'place_in support' do
      space = @board.by_name('Mostaganem')
      space.add :fln_active, 3
      expect(rules.place_in(@board.spaces).city?).to be true
    end

    it 'place_in support and fln_active' do
      space = @board.by_name('Mostaganem')
      space.shift :support
      space.add :fln_active, 3
      expect(rules.place_in(@board.spaces).name).to be 'Mostaganem'
    end

    it 'place_from none' do
      expect(rules.place_from(@board.spaces).nil?).to be true
    end

    it 'place_from most active' do
      @board.by_name('Oran').add :fln_active, 1
      @board.by_name('Batna').add :fln_active, 3
      @board.by_name('Negrine').add :fln_active, 2
      expect(rules.place_from(@board.spaces).name).to be 'Batna'
    end

    it 'remove_from all' do
      space = @board.by_name('Bougie')
      space.add :fln_active, 2
      h = rules.remove_from(space, 6)
      expect(h[:fln_underground]).to be 1
      expect(h[:fln_active]).to be 2
      expect(h[:fln_bases]).to be 1
    end

    it 'remove_from a few' do
      space = @board.by_name('Bougie')
      space.add :fln_active, 1
      h = rules.remove_from(space, 2)
      expect(h[:fln_underground]).to be 1
      expect(h[:fln_active]).to be 1
      expect(h[:fln_bases]).to be 0
    end
  end
end
