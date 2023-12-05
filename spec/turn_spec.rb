# frozen_string_literal: true

require './lib/colonial_twilight/turn'
require './spec/mock_board'

describe ColonialTwilight::Turn do
  before do
    @turn = ColonialTwilight::Turn.new
    @a = Sector.new
    @b = Sector.new
  end

  describe 'Validation' do
    it 'validate operation' do
      expect { @turn.operation_in(:rall, @a, 0) }.to raise_error(Exception)
    end

    it 'validate special activity' do
      expect { @turn.special_activity_in(:bush, @a, 0) }.to raise_error(Exception)
    end

    it '1 operation only' do
      @turn.operation_in(:march, @a, 0)
      expect { @turn.operation_in(:rally, @b, 0) }.to raise_error(Exception)
    end

    it '1 special activity only' do
      @turn.special_activity_in(:extort, @a, 0)
      expect { @turn.special_activity_in(:ambush, @b, 0) }.to raise_error(Exception)
    end

    it 'only 1 operation in limited operation' do
      @turn.reset(true)
      @turn.operation_in(:rally, @a, 0)
      expect { @turn.operation_in(:rally, @a, 0) }.to raise_error(Exception)
    end

    it 'no special activity in limited operation' do
      @turn.reset(true)
      expect { @turn.special_activity_in(:ambush, @a, 0) }.to raise_error(Exception)
    end

    it 'select a sector once for the operation' do
      @turn.operation_in(:rally, @a, 0)
      expect { @turn.operation_in(:rally, @a, 0) }.to raise_error(Exception)
    end

    it 'select a sector once for the special activity' do
      @turn.special_activity_in(:ambush, @a, 0)
      expect { @turn.special_activity_in(:ambush, @a, 0) }.to raise_error(Exception)
    end

    it 'agitate in an unselected space' do
      expect { @turn.agitate_n(@a, 0, 0, false) }.to raise_error(Exception)
    end
  end

  describe 'interrogations' do
    it 'operation done' do
      expect(@turn.operation_done?).to be false
      @turn.operation_in(:rally, @b, 2)
      expect(@turn.operation_done?).to be true
    end

    it 'activity done' do
      expect(@turn.special_activity_done?).to be false
      @turn.special_activity_in(:ambush, @a, 3)
      expect(@turn.special_activity_done?).to be true
    end

    it 'activity done' do
      expect(@turn.may_special_activity?(:ambush)).to be true
      @turn.special_activity_in(:extort, @b, 4).extort
      expect(@turn.may_special_activity?(:extort)).to be true
      expect(@turn.may_special_activity?(:ambush)).to be false
    end

    it 'operation cost' do
      a = @turn.operation_in(:rally, @a, 1)
      @turn.operation_in(:rally, @b, 2)
      b = @turn.special_activity_in(:ambush, @a, 3)
      @turn.special_activity_in(:ambush, @b, 4)
      expect(@turn.operation_cost).to be 3
      expect(a.name == 'Rally').to be true
      expect(b.name == 'Ambush').to be true
    end

    it 'activity cost' do
      @turn.operation_in(:rally, @a, 1)
      @turn.operation_in(:rally, @b, 2)
      @turn.special_activity_in(:ambush, @a, 3)
      @turn.special_activity_in(:ambush, @b, 4)
      expect(@turn.special_activity_cost).to be 7
    end

    it 'cost' do
      @turn.operation_in(:rally, @a, 1)
      @turn.operation_in(:rally, @b, 2)
      @turn.special_activity_in(:ambush, @a, 3)
      @turn.special_activity_in(:ambush, @b, 4)
      expect(@turn.cost).to be 10
    end

    it 'selected spaces' do
      @turn.operation_in(:rally, @a, 1)
      @turn.operation_in(:rally, @b, 2)
      @turn.special_activity_in(:ambush, @a, 3)
      expect(@turn.selected_spaces).to be 2
    end

    it 'inspect' do
      @turn.operation_in(:rally, @a, 1)
      @turn.operation_in(:rally, @b, 2)
      @turn.special_activity_in(:ambush, @a, 3)
      expect(@turn.inspect.instance_of?(String)).to be true
    end
  end

  describe 'Operations' do
    it 'Pass' do
      @turn.pass(1)
      expect(@turn.cost).to eq(-1)
      expect(@turn.actions.size).to eq 1
      expect(@turn.actions[0].steps.size).to eq 1
      expect(@turn.actions[0].steps[0][:kind]).to be :pass
    end

    it 'activate' do
      @turn.special_activity_in(:ambush, @space, 1).activate(1)
      expect(@turn.cost).to eq(1)
      expect(@turn.actions[0].steps.size).to eq 1
      expect(@turn.actions[0].steps[0][:kind]).to be :activate
    end

    it 'transfer' do
      h = { @a => 2, @b => 3 }
      @turn.operation_in(:rally, @space, 1)
           .transfer_to(:available, :fln_active, 1)
           .transfer_from(:available, :fln_bases)
           .transfer_steps(h)
      expect(@turn.cost).to eq(1)
      expect(@turn.actions.size).to eq 1
      expect(@turn.actions[0].steps.size).to eq 4
      expect(@turn.actions[0].steps[0][:kind]).to be :transfer
      expect(@turn.actions[0].steps[1][:kind]).to be :transfer
      expect(@turn.actions[0].steps[2][:kind]).to be :transfer
      expect(@turn.actions[0].steps[3][:kind]).to be :transfer
    end

    it 'shift' do
      @turn.operation_in(:rally, @space, 1)
           .shift(3)
      expect(@turn.cost).to eq(1)
      expect(@turn.actions.size).to eq 1
      expect(@turn.actions[0].steps.size).to eq 1
      expect(@turn.actions[0].steps[0][:kind]).to be :shift
    end

    it 'extort' do
      @turn.operation_in(:rally, @space, -1)
           .extort
      expect(@turn.cost).to eq(-1)
      expect(@turn.actions.size).to eq 1
      expect(@turn.actions[0].steps.size).to eq 1
      expect(@turn.actions[0].steps[0][:kind]).to be :extort
    end

    it 'terror' do
      @turn.operation_in(:terror, @space, 1)
           .terror
      expect(@turn.cost).to eq(1)
      expect(@turn.actions.size).to eq 1
      expect(@turn.actions[0].steps.size).to eq 2
      expect(@turn.actions[0].steps[0][:kind]).to be :set
      expect(@turn.actions[0].steps[0][:kind]).to be :set
    end

    it 'agitate raise if not :rally' do
      @turn.pass(1)
      expect { @turn.agitate_in(@a, 1, 0) }.to raise_error(Exception)
    end

    it 'agitate' do
      @turn.operation_in(:rally, @space, 1)
      @turn.agitate_in(@space, 2, 1)
      expect(@turn.cost).to eq 4
      expect(@turn.actions.size).to eq 2
      expect(@turn.actions[1].steps.size).to eq 1
      expect(@turn.actions[1].steps[0][:kind]).to be :agitate
      expect(@turn.actions[1].steps[0][:terror]).to eq 2
      expect(@turn.actions[1].steps[0][:shift]).to eq 1
    end

    it 'sanitize!' do
      act = @turn.special_activity_in(:subvert, @a, 0)
                 .transfer_to(:available, :algerian_police, 1)
                 .transfer_from(:available, :fln_underground, 1)
      act.steps[0].merge!(:src_control=>:uncontrolled)
      act.steps[1].merge!(:dst_control=>:FLN)
      act.sanitize!
      expect(act.steps[0].key?(:src_control)).to be false
      expect(act.steps[1][:dst_control]).to be :FLN
    end
  end
end
