# frozen_string_literal: true

require './lib/colonial_twilight/forces'

describe ColonialTwilight::Forces do
  describe 'Available' do
    f = ColonialTwilight::Forces.new :available
    it 'nil' do
      %i[control fln_active].each do |sym|
        expect(f.send(sym)).to be nil
      end
    end

    it 'fln_active -> fln_underground' do
      f.add :fln_active, 1
      expect(f.fln_underground).to be 1
    end
  end

  describe 'Casualties' do
    f = ColonialTwilight::Forces.new :casualties
    it 'nil' do
      %i[control fln_active fln_bases].each do |sym|
        expect(f.send(sym)).to be nil
      end
    end

    it 'raise' do
      %i[fln_active fln_bases].each do |sym|
        expect { f.add sym, 1 }.to raise_error(Exception)
      end
    end
  end

  describe 'OutOfPlay' do
    f = ColonialTwilight::Forces.new :out_of_play
    it 'nil' do
      %i[control algerian_troops algerian_police fln_active fln_bases].each do |sym|
        expect(f.send(sym)).to be nil
      end
    end

    it 'raise' do
      %i[algerian_troops algerian_police fln_active fln_bases].each do |sym|
        expect { f.add sym, 1 }.to raise_error(Exception)
      end
    end
  end

  describe 'Country' do
    f = ColonialTwilight::Forces.new :Country
    it 'nil' do
      %i[control algerian_troops algerian_police french_troops french_police].each do |sym|
        expect(f.send(sym)).to be nil
      end
    end

    it 'raise' do
      %i[algerian_troops algerian_police french_troops french_police].each do |sym|
        expect { f.add sym, 1 }.to raise_error(Exception)
      end
    end
  end

  describe 'City' do
    ColonialTwilight::Forces.new :City
  end

  describe 'Sector' do
    f = ColonialTwilight::Forces.new :Sector
    data = { fln_bases: 0, gov_bases: 1, algerian_troops: 2, algerian_police: 3,
             french_troops: 4, french_police: 5, fln_underground: 6, fln_active: 7 }
    f.init data
    it 'init' do
      data.keys.each_with_index do |k, i|
        expect(f.send(k)).to be i
      end
    end

    it 'count bases' do
      expect(f.bases).to be 1
    end

    it 'count fln' do
      expect(f.fln).to be 13
    end

    it 'count guerrillas' do
      expect(f.guerrillas).to be 13
    end

    it 'count troops' do
      expect(f.troops).to be 6
    end

    it 'count police' do
      expect(f.police).to be 8
    end

    it 'switch control' do
      expect(f.control).to be :GOV
      f.add :fln_active, 2
      expect(f.control).to be :uncontrolled
      f.add :fln_active, 1
      expect(f.control).to be :FLN
    end

    it 'inspect' do
      expect(f.inspect.instance_of?(String)).to be true
    end

    it 'raise' do
      expect { f.add :fln_bases, 2 }.to raise_error(Exception)
    end

    it 'raise wrong type' do
      expect { f.add :wrong, 1 }.to raise_error(Exception)
    end

    it 'data' do
      d = f.data
      data.keys do |k, v|
      expect(d[k]).to be v
      end
    end
  end
end
