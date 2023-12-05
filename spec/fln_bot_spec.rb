# frozen_string_literal: true

require './lib/colonial_twilight/fln_bot'
require './spec/mock_board'

class ColonialTwilight::FLNBot
  attr_writer :debug

  def setup(op_limited: true)
    @possible_actions = %i[pass op op_limited] unless op_limited
    @possible_actions = %i[pass op_limited] if op_limited
  end
end

describe ColonialTwilight::FLNBot do
  before do
    @game = Game.new
    @game.board.fln_resources = 1
    @game.board.available_fln_underground = 1
    @bot = ColonialTwilight::FLNBot.new(@game, :FLN)
    @bot.setup
  end

  describe 'Pass' do
    it 'cost' do
      expect(@bot.pass).to be true
      expect(@game.action.cost).to eq(-1)
    end

    it 'steps' do
      expect(@bot.pass).to be true
      expect(@game.action.steps.size).to eq(1)
    end

    it 'kind' do
      expect(@bot.pass).to be true
      expect(@game.action.steps[0][:kind]).to eq(:pass)
    end
  end

  describe 'Extort' do
    it 'nowhere' do
      expect(@bot.extort).to be false
    end

    it 'success' do
      @game.set(pop: 1, fln_underground: 1)
      expect(@bot.extort).to be true
    end

    it 'not if special activity already done' do
      @bot.turn.special_activity_in(:subvert, @game.board.spaces[0], 1)
      @game.set(pop: 1, fln_underground: 1)
      expect(@bot.extort).to be false
    end
  end

  describe 'Terror' do
    it 'nowhere' do
      expect(@bot.terror).to be false
    end

    it 'terror 1' do
      @game.set(pop: 1, fln_underground: 1, support: true)
      expect(@bot.terror).to be true
    end

    it 'terror 2' do
      @game.set(pop: 1, fln_underground: 1, neutral: true, gov_bases: 1)
      expect(@bot.terror).to be true
    end

    it 'terror 1 + extort' do
      @game.board.fln_resources = 0
      @game.set(pop: 1, fln_underground: 2, support: true)
      expect(@bot.terror).to be true
    end

    it 'terror 1 + extort not possible' do
      @game.board.fln_resources = 0
      @game.set(pop: 1, fln_underground: 1, support: true)
      expect(@bot.terror).to be false
    end
  end

  describe 'Attack' do
    def check_transfer(step, what, dst, num)
      expect(step[:kind]).to be :transfer
      expect(step[:what]).to be what
      expect(step[:dst]).to be dst
      expect(step[:num]).to eq num
    end

    def check_activate(step, num)
      expect(step[:kind]).to be :activate
      expect(step[:num]).to eq num
    end

    it 'algerian_police ambush' do
      @game.set(algerian_police: 1, fln_active: 5, fln_underground: 1)
      expect(@bot.attack).to be true
      expect(@game.action.type).to be :ambush
      check_activate(@game.action.steps[0], 1)
      check_transfer(@game.action.steps[1], :algerian_police, :casualties, 1)
      check_transfer(@game.action.steps[2], :fln_active, :available, 1)
    end

    it 'ambush twice then attack' do
      @game.board.fln_resources = 3
      @game.set(french_troops: 1, french_police: 1, algerian_police: 1, fln_active: 3, fln_underground: 3)
      @game.set(gov_bases: 1, algerian_police: 1, fln_active: 4, fln_underground: 2)
      @game.set(algerian_police: 1, fln_active: 1, fln_underground: 5)
      expect(@bot.attack).to be true
      act = @game.actions[0]
      expect(act.type).to be :ambush
      check_activate(act.steps[0], 1)
      check_transfer(act.steps[1], :french_police, :casualties, 1)
      check_transfer(act.steps[2], :fln_active, :available, 1)
      act = @game.actions[1]
      expect(act.type).to be :ambush
      check_activate(act.steps[0], 1)
      check_transfer(act.steps[1], :algerian_police, :casualties, 1)
      check_transfer(act.steps[2], :fln_active, :available, 1)
      act = @game.actions[2]
      expect(act.type).to be :attack
      check_activate(act.steps[0], 5)
      check_transfer(act.steps[1], :algerian_police, :casualties, 1)
      check_transfer(act.steps[2], :fln_active, :available, 1)
    end

    it 'roll to attack' do
      @game.board.fln_resources = 3
      @game.set(algerian_police: 3, fln_active: 2, fln_underground: 1)
      @game.set(algerian_police: 3, fln_active: 2, fln_underground: 1)
      @game.set(algerian_police: 1, fln_active: 2, fln_underground: 2)
      expect(@bot.attack).to be true
      act = @game.actions[2]
      expect(act.type).to be :attack
      check_activate(@game.action.steps[0], 2)
      check_activate(act.steps[0], 2)
      check_transfer(act.steps[1], :algerian_police, :casualties, 1)
      check_transfer(act.steps[2], :fln_active, :available, 1)
    end

    it 'attrition' do
      @game.board.fln_resources = 3
      @game.set(algerian_police: 30, fln_active: 2, fln_underground: 1)
      @game.set(algerian_police: 30, fln_active: 2, fln_underground: 1)
      @game.set(algerian_police: 3, fln_active: 2, fln_underground: 2)
      expect(@bot.attack).to be true
      act = @game.actions[2]
      expect(act.type).to be :attack
      check_activate(@game.action.steps[0], 2)
      check_activate(act.steps[0], 2)
      check_transfer(act.steps[1], :algerian_police, :casualties, 2)
      check_transfer(act.steps[2], :fln_active, :available, 1)
      check_transfer(act.steps[3], :fln_active, :casualties, 1)
    end

    it 'attack + extort' do
      @game.board.fln_resources = 0
      @game.set(algerian_police: 3, fln_active: 2, fln_underground: 1)
      @game.set(name: 'country', pop: 1, fln_underground: 1, independent: true)
      expect(@bot.attack).to be true
    end
  end

  describe 'Subvert' do
    it 'nowhere' do
      expect(@bot.subvert).to be false
    end

    it 'subvert 1' do
      @game.set(fln_underground: 1, algerian_police: 1)
      expect(@bot.subvert).to be true
      expect(@game.actions.size).to be 1
      expect(@game.action.steps.size).to be 1
    end

    it 'subvert 2' do
      @game.set(fln_underground: 1, algerian_police: 1, french_troops: 1)
      expect(@bot.subvert).to be true
      expect(@game.actions.size).to be 1
      expect(@game.action.steps.size).to be 2
    end

    it 'subvert 1 + remove anywhere' do
      @game.set(fln_underground: 1, algerian_police: 1)
      @game.set(fln_underground: 1, algerian_troops: 1, french_troops: 1)
      expect(@bot.subvert).to be true
      expect(@game.actions.size).to be 2
    end

    it 'OP + 2 x remove anywhere' do
      expect(@bot.pass).to be true
      @game.set(name: 'a', fln_underground: 1, algerian_troops: 1, french_troops: 1)
      @game.set(name: 'b', fln_underground: 1, algerian_troops: 1, french_troops: 1)
      expect(@bot.subvert).to be true
      expect(@game.actions.size).to be 3
    end
  end

  describe 'Rally' do
    it 'nowhere' do
      expect(@bot.rally).to be false
    end

    it 'rally 1' do
      @game.set(fln_active: 1, fln_underground: 2)
      expect(@bot.rally).to be true
      expect(@game.action.steps.size).to be 3
    end

    it 'rally 2' do
      @bot.setup(op_limited: false)
      @game.set(fln_active: 2, fln_underground: 2, french_troops: 1)
      expect(@bot.rally).to be true
      expect(@game.action.steps.size).to be 2
    end

    it 'rally 3' do
      @game.set(fln_bases: 1)
      @game.set(fln_bases: 2)
      expect(@bot.rally).to be true
      expect(@game.action.steps.size).to be 1
    end

    it 'rally 4' do
      @game.board.france_track = 2
      expect(@bot.rally).to be true
    end

    it 'rally 5' do
      @game.set(support: true)
      @game.set(support: true)
      expect(@bot.rally).to be true
      expect(@game.action.steps.size).to be 1
    end

    it 'rally 6 + agitate' do
      @game.board.fln_resources = 20
      @game.set(pop: 2, terror: 2)
      @game.set(pop: 2, terror: 3)
      expect(@bot.rally).to be true
      expect(@game.action.cost).to be 3
      expect(@game.actions.size).to be 2
    end

    it 'rally 6 + only reduce terror' do
      @game.board.fln_resources = 9
      @game.set(pop: 2, terror: 8)
      expect(@bot.rally).to be true
      expect(@bot.turn.cost).to be 6
      expect(@game.action.cost).to be 5
      expect(@game.actions.size).to be 2
    end

    it 'rally 6 + extort + agitate' do
      @game.board.fln_resources = 1
      @game.set(pop: 2, terror: 1)
      @game.set(name: 'country', pop: 1, fln_underground: 1, independent: true)
      @game.set(name: 'country', pop: 1, fln_underground: 1, independent: true)
      expect(@bot.rally).to be true
      expect(@game.actions.size).to be 4
    end

    it 'rally 6 + cannot extort => rally 7' do
      @game.board.fln_resources = 1
      @game.set(pop: 2, terror: 1)
      expect(@bot.rally).to be true
      expect(@game.actions.size).to be 1
    end

    it 'rally 7 + limited agitate' do
      @game.keep = true
      @game.board.fln_resources = 9
      @game.set(fln_active: 1, terror: 10)
      expect(@bot.rally).to be true
      expect(@game.actions.size).to be 2
      expect(@game.actions[1].cost).to be 5
    end

    it 'rally 7 + extort + agitate' do
      @game.keep = true
      @game.board.fln_resources = 1
      @game.set(pop: 1, french_police: 3, fln_active: 1, fln_bases: 1, terror: 10)
      @game.set(name: 'country', pop: 1, fln_underground: 1, independent: true)
      @game.set(name: 'country', pop: 1, fln_underground: 1, independent: true)
      @game.set(name: 'country', pop: 1, fln_underground: 1, independent: true)
      expect(@bot.rally).to be true
      expect(@game.actions.size).to be 5
      expect(@game.actions[4].type).to eq :agitate
      expect(@game.actions[4].cost).to be 3
    end

    it 'agitate unselected' do
      @game.keep = true
      @game.board.fln_resources = 3
      @game.set(fln_active: 0, fln_bases: 1, terror: 1)
      expect(@bot.rally).to be true
      expect(@game.actions.size).to be 2
      expect(@game.actions[1].type).to eq :agitate
      expect(@game.actions[1].cost).to be 2
    end

    it '2 rally 7 + rally 8' do
      @bot.setup(op_limited: false)
      @game.board.fln_resources = 3
      @game.set(fln_active: 1, oppose: 1)
      @game.set(fln_active: 1, oppose: 1)
      @game.set(fln_active: 1, oppose: 1)
      @game.set(fln_active: 1, oppose: 1)
      expect(@bot.rally).to be true
      expect(@game.actions.size).to be 3
    end
  end
end
