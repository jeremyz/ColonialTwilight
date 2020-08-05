#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

require 'json'

# FIXME :
#   - json should not be here
#   - has_?
#   - can_?
#
#   check min/max bases, points, tracks
#
# delegate [syms].each do |s| define_method s delegate.instance_method(s) end
#
# scenario  as JSON ?, tools to generate them
#

module ColonialTwilight

  class Forces

    attr_accessor :algerian_troops, :algerian_police
    attr_accessor :french_troops, :french_police
    attr_accessor :fln_underground, :fln_active
    attr_accessor :fln_bases, :gov_bases
    attr_reader :control

    def initialize k
      @algerian_troops = 0
      @algerian_police = 0
      @french_troops = 0
      @french_police = 0
      @gov_bases = 0
      @fln_underground = 0
      @fln_active = 0
      @fln_bases = 0
      @max_bases = 2
      @control = :none
      rm = nil
      case k
      when :available
        rm = [:@control, :@fln_active]
      when :casualties
        rm = [:@control, :@fln_active, :@fln_bases]
      when :out_of_play
        rm = [:@control, :@algerian_troops, :@algerian_police, :@fln_active, :@fln_bases]
      when :Country
        @max_bases = 3
        rm = [:@control, :@algerian_troops, :@algerian_police, :@french_troops, :@french_police, :@gov_bases]
      end
      rm.each do |sym|
        # maybe remove :sym= instead or set @sym to nil
        remove_instance_variable sym
      end unless rm.nil?
    end

    def to_s
      "
      #{gov_bases} GOV bases
        #{french_troops} french troops
        #{french_police} french police
        #{algerian_troops} algerian troops
        #{algerian_police} algerian police
      #{fln_bases} FLN bases
        #{fln_underground} underground Guerrillas
        #{fln_active} active Guerrillas"
    end

    def data
      h={}
      [:algerian_troops, :algerian_police, :french_troops, :french_police,
       :fln_underground, :fln_active, :fln_bases, :gov_bases, :control].each do |sym|
        h[sym] = send(sym) unless send(sym).nil?
      end
      h
    end

    def bases
      @gov_bases||0 + @fln_bases||0
    end

    def add t, n=1
      case t
      when :french_troops; @french_troops += n
      when :french_police; @french_police += n
      when :algerian_troops; @algerian_troops += n
      when :algerian_police; @algerian_police += n
      when :fln_underground; @fln_underground += n
      when :fln_active; @fln_active += n
      else
        raise "unknown force type : #{t}"
      end
      update_control
    end

    def add_base t, n=1
      raise "too much bases in #@name (#{bases} + #{n}) > #@max_bases" if (bases + n) > @max_bases
      @gov_bases += n if t == :gov
      @fln_bases += n if t == :fln
      update_control
    end

    private

    def update_control
      return if @control.nil?
      gov = @algerian_troops + @algerian_police + @french_troops + @french_police + @gov_bases
      fln = @fln_underground + @fln_active + @fln_bases
      if gov == fln; @control = :none
      elsif gov > fln; @control = :GOV
      else @control = :FLN
      end
    end

  end

  class Sector

    MOUNTAIN=1
    COASTAL=2
    BORDER=4

    attr_reader :wilaya, :sector, :name, :resettled
    attr_accessor :pop, :adjacents
    attr_accessor :alignment

    def initialize n, w, s, p, attrs=0
      @name = n
      @wilaya = w
      @sector = s
      @pop = p
      @attributes = attrs
      @descr = "#{self.class.name} #@name #{@wilaya == 0 ? '' : @wilaya}" + (@sector == 0 ? '' : "-#{@sector}")
      @terrain = [mountain? ? 'mountain' : nil ,coastal? ? 'coastal' : nil, border? ? 'border' : nil].reject(&:nil?).join '/'
      @forces = Forces.new self.class.name.split('::')[-1].to_sym
      @alignment = :neutral
      @resettled = false
    end

    def to_s
      "#@descr #@terrain
      control    : #{@forces.control}
      alignment  : #@alignment
      population : #{@pop}#{@resettled ? ' resettled' : ''}
      forces     : #{@forces}
      adjs       : #{@adjacents}"
    end

    def data
      { :name=>@name, :alignment=>@alignment, :pop=>@pop, :resettled=>@resettled }.merge(@forces.data)
    end

    def city?; false; end
    def country?; false; end
    def border?; (@attributes & BORDER) == BORDER end
    def coastal?; (@attributes & COASTAL) == COASTAL end
    def mountain?; (@attributes & MOUNTAIN) == MOUNTAIN end
    def control; @forces.control; end
    def add_gov_base n=1; @forces.add_base :gov, n; end
    def add_fln_base n=1; @forces.add_base :fln, n; end
    def add_french_troops n=1; @forces.add :french_troops, n; end
    def add_french_police n=1; @forces.add :french_police, n; end
    def add_algerian_troops n=1; @forces.add :algerian_troops, n; end
    def add_algerian_police n=1; @forces.add :algerian_police, n; end
    def add_fln_underground n=1; @forces.add :fln_underground, n; end
    def add_fln_active n=1; @forces.add :fln_active, n; end
    def french_troops; @forces.french_troops end
    def french_police; @forces.french_police end
    def algerian_troops; @forces.algerian_troops end
    def algerian_police; @forces.algerian_police end
    def fln_underground; @forces.fln_underground end
    def fln_active; @forces.fln_active end
    def gov_bases; @forces.gov_bases end
    def fln_bases; @forces.fln_bases end
    def resettle!
      raise "can't resettle a country " if country?
      raise "can't resettle a sector with a population > 1" if @pop != 1
      @pop = 0
      @resettled = true
    end

  end

  class City < Sector
    def initialize n, w, p, attrs=0
      super n, w, 0, p, attrs
    end
    def city?; true; end
  end

  class Country < Sector

    attr_reader :independant

    def initialize n
      super n, 0, 0, 1, MOUNTAIN|BORDER|COASTAL
      @descr += " #{@independant ? 'Independant' : 'French'}"
    end
    def add_gov_base n=1; raise "no gov bases allowed in #@name"  end
    def country?; true; end
  end


  class Board

    FRANCE_TRACK=['A','B','C','D','E'].freeze

    attr_accessor :commitment
    attr_accessor :gov_resources, :fln_resources
    attr_accessor :support_commitment, :opposition_bases
    attr_accessor :resettled_sectors
    attr_accessor :france_track, :border_zone_track

    attr_reader :spaces, :names

    def initialize
      @names = []
      @spaces = {}
      @capabilities = []
      @available = Forces.new :available
      @casualties = Forces.new :casualties
      @out_of_play = Forces.new :out_of_play
      feed
    end

    def load scenario
      case scenario
      when :short; short
      when :medium; medium
      when :full; full
      else raise "unknown scenario : #{scenario}"
      end
    end

    def sectors
      @spaces.select{ |k,s| not s.country? }
    end

    def data
      h = { }
      [:commitment, :gov_resources, :fln_resources, :support_commitment, :opposition_bases, :resettled_sectors, :france_track, :border_zone_track].each do |sym|
        h[sym] = send(sym)
      end
      h[:capabilities] = @capabilities
      h[:available] = @available.data
      h[:casualties] = @casualties.data
      h[:out_of_play] = @out_of_play.data
      h[:spaces] = @spaces.inject([])do |a,(k,s)| a << s.data end
      h
    end

    def to_json
      # JSON.pretty_generate(data)
      JSON.generate(data)
    end

    def save
      File.open('save.json','w') do |f|
        f.write(JSON.generate(data))
      end
    end

    def resettle sector
      @spaces[sector].resettle!
      @resettled_sectors += 1
    end

    def compute_victory
      @opposition_bases = 0
      @support_commitment = @commitment
      @spaces.each do |n,s|
        @opposition_bases += s.fln_bases
        @opposition_bases += s.pop if s.alignment == :oppose
        @support_commitment += s.pop if s.alignment == :support
      end
    end

    private

    def add k, *args
      s = k.new *args
      # puts s
      @names << s.name
      @spaces[s.name] = s
    end

    def adjacents i, *args
      @spaces[@names[i]].adjacents = args
      # @spaces[@names[i]].adjacents = args.map { |i| @names[i] }
      # puts @spaces[@names[i]]
    end

    def feed
      mountain=Sector::MOUNTAIN
      border=Sector::BORDER
      coastal=Sector::COASTAL
      add Sector, 'Barika', 'I', 1, 1, mountain                 #  0
      add Sector, 'Batna', 'I', 2, 0, mountain                  #  1
      add Sector, 'Biskra', 'I', 3, 0, border                   #  2
      add Sector, 'Oum El Bouaghi', 'I', 4, 0, mountain         #  3
      add Sector, 'Tebessa', 'I', 5, 1, mountain|border         #  4
      add Sector, 'Negrine', 'I', 6, 0, mountain|border         #  5
      add City, 'Constantine', 'II', 2                          #  6
      add Sector, 'Setif', 'II', 1, 1, mountain|coastal         #  7
      add Sector, 'Philippeville', 'II', 2, 2, mountain|coastal #  8
      add Sector, 'Souk Ahras', 'II', 3, 2, coastal|border      #  9
      add Sector, 'Tizi Ouzou', 'III', 1, 2, mountain|coastal   # 10
      add Sector, 'Bordj Bou Arreridj', 'III', 2, 1, mountain   # 11
      add Sector, 'Bougie', 'III', 3, 2, mountain|coastal       # 12
      add City, 'Algiers', 'IV', 3, coastal                     # 13
      add Sector, 'Medea', 'IV', 1, 2, mountain|coastal         # 14
      add Sector, 'Orleansville', 'IV', 2, 2, mountain|coastal  # 15
      add City, 'Oran', 'V', 2, coastal                         # 16
      add Sector, 'Mecheria', 'V', 1, 0, mountain|border        # 17
      add Sector, 'Tlemcen', 'V', 2, 1, border|coastal          # 18
      add Sector, 'Sidi Bel Abbes', 'V', 3, 1, coastal          # 19
      add Sector, 'Mostaganem', 'V', 4, 2, mountain|coastal     # 20
      add Sector, 'Saida', 'V', 5, 0, mountain                  # 21
      add Sector, 'Mascara', 'V', 6, 0, mountain                # 22
      add Sector, 'Tiaret', 'V', 7, 0, mountain                 # 23
      add Sector, 'Ain Sefra', 'V', 8, 0, border                # 24
      add Sector, 'Laghouat', 'V', 9, 0                         # 25
      add Sector, 'Sidi Aissa', 'VI', 1, 0, mountain            # 26
      add Sector, 'Ain Oussera', 'VI', 2, 1, mountain           # 27
      add Country, 'Moroco'                                     # 28
      add Country, 'Tunisia'                                    # 29
      adjacents  0, 1, 2, 3, 7, 8, 11, 19
      adjacents  1, 0, 2, 3, 5
      adjacents  2, 0, 1, 5, 25, 26, 29
      adjacents  3, 0, 1, 4, 5, 8, 9
      adjacents  4, 3, 5, 9, 29
      adjacents  5, 1, 2, 3, 4, 29
      adjacents  6, 7, 8
      adjacents  7, 0, 6, 8, 11, 12
      adjacents  8, 0, 3, 7, 6, 9
      adjacents  9, 3, 4, 8, 29
      adjacents 10, 11, 12, 14
      adjacents 11, 0, 7, 10, 12, 14, 26
      adjacents 12, 7, 10, 11
      adjacents 13, 14
      adjacents 14, 10, 11, 13, 15, 26, 27
      adjacents 15, 14, 20, 23, 27
      adjacents 16, 19
      adjacents 17, 18, 21, 24, 28
      adjacents 18, 17, 19, 21, 28
      adjacents 19, 16, 18, 20, 21, 22
      adjacents 20, 15, 19, 22, 23
      adjacents 21, 17, 18, 19, 22, 24
      adjacents 22, 19, 20, 21, 23, 24
      adjacents 23, 15, 20, 22, 24, 27
      adjacents 24, 17, 21, 22, 23, 25, 27, 28
      adjacents 25, 2, 24, 26, 27
      adjacents 26, 0, 2, 11, 14, 25, 27
      adjacents 27, 14, 15, 23, 24, 25, 26
      adjacents 28, 17, 18, 24
      adjacents 29, 2, 4, 5, 8
    end

    def set_sector i, h, align=nil
      s = @spaces[@names[i]]
      s.alignment = align unless align.nil?
      s.add_gov_base h[:govb] if h.has_key? :govb
      s.add_fln_base h[:flnb] if h.has_key? :flnb
      s.add_french_troops h[:ft] if h.has_key? :ft
      s.add_french_police h[:fp] if h.has_key? :fp
      s.add_algerian_troops h[:at] if h.has_key? :at
      s.add_algerian_police h[:ap] if h.has_key? :ap
      s.add_fln_underground h[:fln] if h.has_key? :fln
      # puts s
    end

    def short
      self.commitment = 15
      self.fln_resources = 15
      self.gov_resources = 20
      self.resettled_sectors = 0
      self.france_track = 4
      self.border_zone_track = 3
      @out_of_play.fln_underground = 5
      @available.gov_bases = 2
      @available.french_police = 4
      @available.fln_bases = 7
      @available.fln_underground = 8
      resettle 'Setif'
      resettle 'Tlemcen'
      resettle 'Bordj Bou Arreridj'
      raise "resettled sectors not counted" if resettled_sectors != 3
      set_sector  0, {:ap=>1, :fln=>1}, :oppose
      set_sector  2, {:fp=>1}
      set_sector  4, {:ap=>1, :fln=>1}, :oppose
      set_sector  5, {:fp=>1}
      set_sector  6, {:fp=>1}, :support
      set_sector  7, {:fln=>1}
      set_sector  8, {:ft=>4, :ap=>1, :govb=>1}
      set_sector  9, {:ft=>1, :ap=>1, :govb=>1, :fln=>1, :flnb=>1}, :oppose
      set_sector 10, {:fp=>1, :fln=>1, :flnb=>1}, :oppose
      set_sector 11, {:fp=>1}
      set_sector 12, {:fp=>1, :fln=>1, :flnb=>1}, :oppose
      set_sector 13, {:ft=>4, :at=>1, :fp=>1}, :support
      set_sector 14, {:at=>1, :govb=>1}
      set_sector 15, {:fp=>1, :ap=>1, :fln=>1, :flnb=>1}, :oppose
      set_sector 16, {:at=>1, :fp=>1, :ap=>1}, :support
      set_sector 17, {:fp=>1, :ap=>1}
      set_sector 18, {:fp=>2, :fln=>1}
      set_sector 19, {:fp=>1, :govb=>1}
      set_sector 20, {:fp=>1}
      set_sector 22, {:fp=>1}
      set_sector 23, {:fp=>1}
      set_sector 24, {:fp=>1}
      set_sector 27, {}, :oppose
      set_sector 28, {:fln=>4, :flnb=>2}
      set_sector 29, {:fln=>5, :flnb=>2}
      compute_victory
      raise "wrong opposition bases" if @opposition_bases != 19
      raise "wrong support_commitment" if @support_commitment != 22
    end

    def medium
      raise 'MEDIUM scenario net implemented yet'
    end

    def full
      raise 'FULL scenario net implemented yet'
    end

  end

end

# class ColonialTwilight::Sector
#   undef :adjacents=
# end

if $PROGRAM_NAME == __FILE__
  def check b
    # puts '--- Coastal'
    # b.spaces.select{ |k,s| s.coastal? }.each { |k,s| puts s.name }
    raise "coastal sectors error" if b.spaces.select{ |k,s| s.coastal? }.size != 14
    # puts '--- not Mountain'
    # b.spaces.select{ |k,s| not s.mountain? }.each { |k,s| puts s.name }
    raise "not moauntain sectors error" if b.spaces.select{ |k,s| not s.mountain? }.size != 9
    # puts '--- Border'
    # b.spaces.select{ |k,s| s.border? }.each { |k,s| puts s.name }
    raise "border sectors error" if b.spaces.select{ |k,s| s.border? }.size != 9
    # puts '--- City'
    # b.spaces.select{ |k,s| s.city? }.each { |k,s| puts s.name }
    raise "city sectors error" if b.spaces.select{ |k,s| s.city? }.size != 3
    [[0,11],[1,9],[2,9],[3,1]].each do |p,n|
      # puts "--- Population #{p}"
      # b.spaces.select{ |k,s| s.pop==p }.each { |k,s| puts s.name }
      raise "population #{p} error" if b.spaces.select{ |k,s| s.pop==p}.size != n
    end
    raise "sectors count wrong" if b.sectors.size != 28
  end

  def check_forces what, b, v
    sup, opp, gov, fln = 0, 0, 0, 0
    ft, fp, at, ap, g = 0, 0, 0, 0, 0
    gb, fb = 0, 0
    b.spaces.each do |n,s|
      sup += 1 if s.alignment == :support
      opp += 1 if s.alignment == :oppose
      gov += 1 if s.control == :GOV
      fln += 1 if s.control == :FLN
      ft += s.french_troops unless s.french_troops.nil?
      fp += s.french_police unless s.french_police.nil?
      at += s.algerian_troops unless s.algerian_troops.nil?
      ap += s.algerian_police unless s.algerian_police.nil?
      g += s.fln_underground
      gb += s.gov_bases unless s.gov_bases.nil?
      fb += s.fln_bases
    end
    raise "wrong support #{sup} != #{v[0]}" if sup != v[0]
    raise "wrong oppose #{opp} != #{v[1]}" if opp != v[1]
    raise "wrong GOV control #{gov} != #{v[2]}" if gov != v[2]
    raise "wrong FLN control #{fln} != #{v[3]}" if fln != v[3]
    raise "wrong french troops #{ft} != #{v[4]}" if ft != v[4]
    raise "wrong french police  #{fp} != #{v[5]}" if fp != v[5]
    raise "wrong algerian troops #{at} != #{v[6]}" if at != v[6]
    raise "wrong algerian police #{ap} != #{v[7]}" if ap != v[7]
    raise "wrong Guerrillas #{g} != #{v[8]}" if g != v[8]
    raise "wrong GOV bases #{gb} != #{v[9]}" if gb != v[9]
    raise "wrong FLN bases #{fb} != #{v[10]}" if fb != v[10]
  end

  b = ColonialTwilight::Board.new
  puts 'check'
  check b
  b.load :short
  check_forces 'short', b, [3, 7, 16, 3, 9, 17, 3, 7, 17, 4, 8]
  puts 'ok'
end
