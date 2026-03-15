# frozen_string_literal: true

require './lib/colonial_twilight/actions/fln/rally'
require './lib/colonial_twilight/actions/fln/agitate'
require './lib/colonial_twilight/actions/fln/attack'
require './lib/colonial_twilight/actions/fln/march'
require './lib/colonial_twilight/actions/fln/terror'
require './lib/colonial_twilight/actions/fln/extort'
require './lib/colonial_twilight/actions/fln/subvert'
require './lib/colonial_twilight/actions/fln/ambush'
require './lib/colonial_twilight/actions/fln/oas'
require './lib/colonial_twilight/board'
require './spec/mock_board'

describe ColonialTwilight::Actions::FLN do
  before do
    @board = ColonialTwilight::Board.new
  end

  describe 'Rally' do
    let(:action_class) { ColonialTwilight::Actions::FLN::Rally }

    it 'collects spaces where operation can be conducted' do
      # all but countries
      expect(action_class.possible_spaces(@board).size).to eq(28)
    end

    it 'collects spaces where operation can be conducted' do
      @board.load :short
      # 25 sectors + 2 countries
      expect(action_class.possible_spaces(@board).size).to eq(27)
    end

    it 'applicable? France track' do
      t = Track.new(5, 'France track')
      expect(action_class.applicable?(t)).to be true
      t = Track.new(5, 'France ')
      expect(action_class.applicable?(t)).to be false
    end

    it 'applicable? sector' do
      a = Sector.new
      expect(action_class.applicable?(a)).to be true
    end

    it 'applicable? in city not at support' do
      a = Sector.new({ name: 'city', support: false })
      expect(action_class.applicable?(a)).to be true
    end

    it 'not applicable? in city at support' do
      a = Sector.new({ name: 'city', support: true })
      expect(action_class.applicable?(a)).to be false
    end

    it 'applicable? in independent country' do
      a = Sector.new({ name: 'country', independent: true })
      expect(action_class.applicable?(a)).to be true
    end

    it 'not applicable? not in not independent country' do
      a = Sector.new({ name: 'country', independent: false })
      expect(action_class.applicable?(a)).to be false
    end

    it 'may place 1 guerrillas' do
      a = Sector.new({ pop: 3 })
      modes = action_class.available_modes(a)
      expect(modes.keys.size).to eq(1)
      expect(modes[:place_guerilla]).to eq(1)
    end

    it 'may place pop + base guerrillas' do
      a = Sector.new({ pop: 3, fln_bases: 2 })
      modes = action_class.available_modes(a)
      expect(modes.keys.size).to eq(1)
      expect(modes[:place_guerilla]).to eq(5)
    end

    it 'may flip underground guerillas' do
      a = Sector.new({ fln_active: 3, fln_underground: 2, fln_bases: 1 })
      modes = action_class.available_modes(a)
      expect(modes.keys.size).to eq(3)
      expect(modes[:place_base]).to eq(1)
      expect(modes[:place_guerilla]).to eq(1)
      expect(modes[:underground]).to eq(3)
    end

    it 'may create action within available modes' do
      a = Sector.new({ fln_active: 3, fln_underground: 2, fln_bases: 1 })
      expect { action_class.new(a, { underground: 3 }) }.not_to raise_error
      expect(action_class.new(a, { underground: 3 }).cost).to eq(1)
    end

    it 'may not create action within a not applicable space' do
      a = Sector.new({ name: 'city', support: true })
      expect { action_class.new(a, {}) }.to raise_error(/not applicable/)
    end

    it 'may not create action within higher value' do
      a = Sector.new({ fln_active: 3, fln_underground: 2, fln_bases: 1 })
      expect { action_class.new(a, { underground: 4 }) }.to raise_error(/value:/)
    end

    it 'may create action within available modes' do
      a = Sector.new({ fln_active: 3, fln_underground: 2, fln_bases: 1 })
      expect { action_class.new(a, { wrong: 3 }) }.to raise_error(/mode:/)
    end

    it 'may agitate and compute cost' do
      a = Sector.new({ fln_active: 3, fln_underground: 2, fln_bases: 1, terror: 2 })
      expect { action_class.new(a, { underground: 3 }).agitate!({ remove_terror: 1 }) }.not_to raise_error
      expect(action_class.new(a, { underground: 3 }).agitate!({ remove_terror: 1 }).cost).to eq(2)
      expect(action_class.new(a, { underground: 3 }).agitate!({ remove_terror: 2 }).cost).to eq(3)
    end

    it 'may not agitate if not applicable' do
      a = Sector.new({ fln_active: 3, fln_underground: 2, fln_bases: 1, oppose: true })
      expect { action_class.new(a, { underground: 3 }).agitate!({ remove_terror: 1 }) }.to raise_error(/not applicable/)
    end

    it 'may not agitate twice' do
      a = Sector.new({ fln_active: 3, fln_underground: 2, fln_bases: 1, terror: 1 })
      expect { action_class.new(a, { underground: 3 }).agitate!({ remove_terror: 1 }).agitate!({ remove_terror: 1 }) }.to raise_error(/agitate! called/)
    end
  end

  describe 'Attack' do
    let(:action_class) { ColonialTwilight::Actions::FLN::Attack }

    it 'is applicable where FLN and GOV are present' do
      a = Sector.new(fln_active: 1, gov_cubes: 1)
      expect(action_class.applicable?(a)).to be true
    end

    it 'is not applicable without FLN' do
      a = Sector.new(fln_active: 0, gov_cubes: 1)
      expect(action_class.applicable?(a)).to be false
    end

    it 'is not applicable without GOV' do
      a = Sector.new(fln_active: 1, gov_cubes: 0)
      expect(action_class.applicable?(a)).to be false
    end

    it 'has no modes' do
      a = Sector.new(fln_active: 1, gov_cubes: 1)
      expect(action_class.available_modes(a).empty?).to be true
    end

    it 'can have an ambush' do
      a = Sector.new(fln_active: 1, fln_underground: 1, gov_cubes: 1)
      action = action_class.new(a)
      expect { action.ambush! }.not_to raise_error
    end
  end

  describe 'March' do
    let(:action_class) { ColonialTwilight::Actions::FLN::March }

    it 'is applicable where FLN guerrillas are present' do
      a = Sector.new(fln_active: 1)
      expect(action_class.applicable?(a)).to be true
    end

    it 'is not applicable without FLN guerrillas' do
      a = Sector.new(fln_active: 0)
      expect(action_class.applicable?(a)).to be false
    end

    it 'calculates cost based on destinations' do
      a = Sector.new(fln_active: 5)
      allow(a).to receive(:adjacents).and_return([1, 2, 3])
      action = action_class.new(a, { 1 => 2, 2 => 3 })
      expect(action.cost).to eq(2)
    end
  end

  describe 'Terror' do
    let(:action_class) { ColonialTwilight::Actions::FLN::Terror }

    it 'is applicable in populated space with underground FLN' do
      a = Sector.new(pop: 1, fln_underground: 1)
      expect(action_class.applicable?(a)).to be true
    end

    it 'is not applicable in unpopulated space' do
      a = Sector.new(pop: 0, fln_underground: 1)
      expect(action_class.applicable?(a)).to be false
    end

    it 'is not applicable without underground FLN' do
      a = Sector.new(pop: 1, fln_underground: 0)
      expect(action_class.applicable?(a)).to be false
    end

    it 'is not applicable in countries' do
      a = Sector.new(name: 'country', pop: 1, fln_underground: 1)
      expect(action_class.applicable?(a)).to be false
    end

    it 'has no mode' do
      a = Sector.new(pop: 1, fln_underground: 1)
      expect(action_class.available_modes(a).empty?).to be true
    end
  end

  describe 'Extort' do
    let(:action_class) { ColonialTwilight::Actions::FLN::Extort }

    it 'is applicable in populated space with underground FLN and FLN control' do
      a = Sector.new(pop: 1, fln_underground: 1, fln_active: 2, gov_cubes: 0)
      expect(action_class.applicable?(a)).to be true
    end

    it 'is applicable in independent countries with underground FLN' do
      a = Sector.new(name: 'country', independent: true, fln_underground: 1)
      expect(action_class.applicable?(a)).to be true
    end

    it 'is not applicable without FLN control in sector' do
      a = Sector.new(pop: 1, fln_underground: 1, fln_active: 0, gov_cubes: 2)
      expect(action_class.applicable?(a)).to be false
    end
  end

  describe 'Subvert' do
    let(:action_class) { ColonialTwilight::Actions::FLN::Subvert }

    it 'is applicable with underground FLN and Algerian cubes' do
      a = Sector.new(fln_underground: 1, algerian_police: 1)
      expect(action_class.applicable?(a)).to be true
    end

    it 'provides replace_police and remove_police modes' do
      a = Sector.new(fln_underground: 1, algerian_police: 2)
      modes = action_class.available_modes(a)
      expect(modes[:replace_police]).to eq(1)
      expect(modes[:remove_police]).to eq(2)
      expect(modes[:remove_troops]).to be_nil
    end

    it 'provides replace_police and remove_troops modes' do
      a = Sector.new(fln_underground: 1, algerian_troops: 2)
      modes = action_class.available_modes(a)
      expect(modes[:replace_police]).to be_nil
      expect(modes[:remove_police]).to be_nil
      expect(modes[:remove_troops]).to eq(2)
    end

    it 'may chain subvert in 2 spaces' do
      a = Sector.new(fln_underground: 1, algerian_police: 2)
      b = Sector.new(fln_underground: 1, algerian_troops: 1)
      act = action_class.new(a, { remove_police: 1 })
      expect { act.subvert!(b, { remove_troops: 1 }) }.to_not raise_error
      expect { act.subvert!(b, { remove_troops: 2 }) }.to raise_error(/subvert! called/)
      act = action_class.new(a, { remove_police: 1 })
      b = Sector.new(fln_underground: 1, algerian_police: 2)
      expect { act.subvert!(b, { remove_police: 2 }) }.to raise_error(/remove 3 police/)
      b = Sector.new(fln_underground: 1, algerian_troops: 2)
      act = action_class.new(a, { remove_police: 1 })
      expect { act.subvert!(b, { remove_troops: 2 }) }.to raise_error(/remove 1 police/)
    end

    it 'cannot chain after replace_police' do
      a = Sector.new(fln_underground: 1, algerian_police: 2)
      b = Sector.new(fln_underground: 1, algerian_troops: 1)
      act = action_class.new(a, { replace_police: 1 })
      expect { act.subvert!(b, {}) }.to raise_error(/cannot subvert! after/)
      act = action_class.new(a, { remove_police: 1 })
      expect { act.subvert!(b, { replace_police: 1 }) }.to raise_error(/cannot subvert! with/)
    end
  end

  describe 'Ambush' do
    let(:action_class) { ColonialTwilight::Actions::FLN::Ambush }

    it 'is applicable with underground FLN and GOV present' do
      a = Sector.new(fln_underground: 1, gov_cubes: 1)
      expect(action_class.applicable?(a)).to be true
    end
  end

  describe 'OAS' do
    let(:action_class) { ColonialTwilight::Actions::FLN::Oas }

    it 'is applicable in populated space with no terror and not a country' do
      a = Sector.new(pop: 1, terror: 0)
      expect(action_class.applicable?(a)).to be true
    end

    it 'is not applicable if terror present' do
      a = Sector.new(pop: 1, terror: 1)
      expect(action_class.applicable?(a)).to be false
    end
  end
end
