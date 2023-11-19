# frozen_string_literal: true

require './lib/colonial_twilight/spaces'
# require './spec/mock_board'

describe ColonialTwilight::Track do
  before do
    @t = ColonialTwilight::Track.new(10)
  end

  it 'initialize' do
    expect(@t.v).to eq 0
  end

  it 'shift' do
    expect(@t.shift(3)).to eq 3
    expect(@t.shift(-2)).to eq 1
  end

  it 'clamp' do
    expect(@t.clamp(12)).to eq 10
  end

  it 'overflow' do
    expect { @t.shift(11) }.to raise_error(Exception)
  end

  it 'data' do
    expect(@t.shift(3)).to eq 3
    expect(@t.data).to eq 3
  end
end

describe ColonialTwilight::Sector do
  before do
    @s = ColonialTwilight::Sector.new('Name', 'Wilaya', 'I', 0)
  end

  it 'to_s data inspect' do
    expect(@s.to_s).to eq 'Name'
    expect(@s.data.instance_of?(Hash)).to be true
    expect(@s.inspect.instance_of?(String)).to be true
  end

  it 'is a Sector' do
    expect(@s.sector?).to be true
    expect(@s.city?).to be false
    expect(@s.country?).to be false
  end

  it 'has border' do
    s = ColonialTwilight::Sector.new('Name', 'Wilaya', 'I', 1, ColonialTwilight::Sector::BORDER)
    expect(s.border?).to be true
    expect(s.coastal?).to be false
    expect(s.mountain?).to be false
  end

  it 'is coastal' do
    s = ColonialTwilight::Sector.new('Name', 'Wilaya', 'I', 1, ColonialTwilight::Sector::COASTAL)
    expect(s.border?).to be false
    expect(s.coastal?).to be true
    expect(s.mountain?).to be false
  end

  it 'has mountains' do
    s = ColonialTwilight::Sector.new('Name', 'Wilaya', 'I', 1, ColonialTwilight::Sector::MOUNTAIN)
    expect(s.border?).to be false
    expect(s.coastal?).to be false
    expect(s.mountain?).to be true
  end

  it 'has all' do
    s = ColonialTwilight::Sector.new('Name', 'Wilaya', 'I', 1, ColonialTwilight::Sector::BORDER ||
      ColonialTwilight::Sector::COASTAL || ColonialTwilight::Sector::MOUNTAIN)
    expect(s.border?).to be true
    expect(s.coastal?).to be false
    expect(s.mountain?).to be false
  end

  it 'terror' do
    expect(@s.terror?).to be false
    expect(@s.terror).to eq 0
    expect(@s.shift_terror(2)).to eq 2
    expect(@s.terror?).to be true
    expect(@s.terror).to eq 2
    expect { @t.shift_terrort(-3) }.to raise_error(Exception)
  end

  it 'alignment' do
    expect(@s.oppose?).to be false
    expect(@s.neutral?).to be true
    expect(@s.support?).to be false
    expect { @s.shift :wrong }.to raise_error(Exception)
  end

  it 'shift alignment toward oppose' do
    expect(@s.shift(:oppose)).to be :oppose
    expect(@s.oppose?).to be true
    expect(@s.neutral?).to be false
    expect(@s.support?).to be false
  end

  it 'shift alignment toward support' do
    expect(@s.shift(:support)).to be :support
    expect(@s.oppose?).to be false
    expect(@s.neutral?).to be false
    expect(@s.support?).to be true
  end

  it 'control' do
    expect(@s.fln_control?).to be false
    expect(@s.uncontrolled?).to be true
    expect(@s.gov_control?).to be false
  end

  it 'control fln' do
    @s.add :fln_active
    expect(@s.fln_control?).to be true
    expect(@s.uncontrolled?).to be false
    expect(@s.gov_control?).to be false
  end

  it 'control gov' do
    @s.add :french_troops
    expect(@s.fln_control?).to be false
    expect(@s.uncontrolled?).to be false
    expect(@s.gov_control?).to be true
  end

  it 'resettle' do
    expect { @s.resettle! }.to raise_error(Exception)
    @s.pop = 2
    expect { @s.resettle! }.to raise_error(Exception)
    @s.pop = 1
    @s.resettle!
    expect(@s.resettled?).to be true
    expect(@s.pop).to eq 0
  end

  it 'activate' do
    @s.add :fln_active, 1
    @s.add :fln_underground, 2
    expect(@s.activate(2)).to eq 3
  end
end

describe ColonialTwilight::City do
  before do
    @c = ColonialTwilight::City.new('Name', 'Wilaya', 'I', 0)
  end

  it 'is a City' do
    expect(@c.sector?).to be false
    expect(@c.city?).to be true
    expect(@c.country?).to be false
  end
end

describe ColonialTwilight::Country do
  before do
    @c = ColonialTwilight::Country.new('Name')
  end

  it 'is a Coutry' do
    expect(@c.sector?).to be false
    expect(@c.city?).to be false
    expect(@c.country?).to be true
  end

  it 'independent' do
    expect(@c.independent?).to be false
    expect(@c.independent!).to be true
    expect(@c.independent?).to be true
  end
end
