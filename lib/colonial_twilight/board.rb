#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

module ColonialTwilight

  class Forces

    attr_accessor :algerian_troops, :algerian_police
    attr_accessor :french_troops, :french_police
    attr_accessor :fln_underground, :fln_active
    attr_accessor :fln_bases, :gov_bases
    attr_reader :max_bases, :control

    def initialize k
      @algerian_troops = 0
      @algerian_police = 0
      @french_troops = 0
      @french_police = 0
      @gov_bases = 0
      @fln_underground = 0
      @fln_active = 0
      @fln_bases = 0
      @max_bases = nil
      @control = :uncontrolled
      rm = nil
      case k
      when :available
        rm = [:@control, :@fln_active]
      when :casualties
        rm = [:@control, :@fln_active, :@fln_bases]
      when :out_of_play
        rm = [:@control, :@algerian_troops, :@algerian_police, :@fln_active, :@fln_bases]
      when :Country
        @max_bases = 2
        rm = [:@control, :@algerian_troops, :@algerian_police, :@french_troops, :@french_police, :@gov_bases]
      when :Sector
        @max_bases = 2
      end
      rm.each do |sym|
        instance_variable_set(sym, nil)
      end unless rm.nil?
    end

    def to_s; inspect end
    def inspect
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
      (@gov_bases||0) + (@fln_bases||0)
    end

    def fln
      guerrillas + (@fln_bases||0)
    end

    def guerrillas
      (@fln_underground||0) + (@fln_active||0)
    end

    def gov
      gov_cubes + (@gov_bases||0)
    end

    def gov_cubes
      french_cubes + algerian_cubes
    end

    def french_cubes
      (@french_troops||0) + (@french_police||0)
    end

    def algerian_cubes
      (@algerian_troops||0) + (@algerian_police||0)
    end

    def troops
      (@french_troops||0) + (@algerian_troops||0)
    end

    def police
      (@french_police||0) + (@algerian_police||0)
    end

    def add t, n=1
      case t
      when :french_troops; @french_troops += n
      when :french_police; @french_police += n
      when :algerian_troops; @algerian_troops += n
      when :algerian_police; @algerian_police += n
      when :fln_underground; @fln_underground += n
      when :fln_active; @fln_active += n
      when :gov_base; add_base :gov_base, n
      when :fln_base; add_base :fln_base, n
      else
        raise "unknown force type : #{t}"
      end
      update_control
    end

    private

    def add_base t, n=1
      raise "too much bases in #@name (#{bases} + #{n}) > #@max_bases" if not @max_bases.nil? and (bases + n) > @max_bases
      @gov_bases += n if t == :gov_base
      @fln_bases += n if t == :fln_base
    end

    def update_control
      return if @control.nil?
      @control = (
          case gov <=> fln
          when  0; :uncontrolled
          when  1; :GOV
          when -1; :FLN
          end
      )
    end

  end

  class Track
    attr_accessor :v
    def initialize max
      @v = 0
      @max = max
    end
    def shift v
      w = @v + v
      return false if (w < 0 or w > @max)
      @v = w
      true
    end
    def clamp v
      @v = (@v + v).clamp(0, @max)
    end
    def data; @v end
  end

  class Box < Forces
    attr_reader :name
    def initialize sym
      super sym
      @name = sym
    end
  end

  class Sector

    MOUNTAIN=1
    COASTAL=2
    BORDER=4

    attr_reader :wilaya, :sector, :name, :resettled
    attr_accessor :pop, :terror, :adjacents
    attr_accessor :alignment

    def initialize n, w, s, p, attrs=0
      @name = n
      @wilaya = w
      @sector = s
      @pop = p
      @terror = 0
      @attributes = attrs
      @descr = "#{self.class.name} #@name #{@wilaya == 0 ? '' : @wilaya}" + (@sector == 0 ? '' : "-#{@sector}")
      @terrain = [mountain? ? 'mountain' : nil ,coastal? ? 'coastal' : nil, border? ? 'border' : nil].reject(&:nil?).join '/'
      @forces = Forces.new self.class.name.split('::')[-1].to_sym
      @alignment = :neutral
      @resettled = false
    end

    def to_s; @name end
    def inspect
      "#@descr #@terrain
      control    : #{@forces.control}
      alignment  : #@alignment
      terror     : #@terror
      population : #{@pop}#{@resettled ? ' resettled' : ''}
      forces     : #{@forces}
      adjs       : #{@adjacents}"
    end

    def data
      { :name=>@name, :alignment=>@alignment, :terror=>@terror, :pop=>@pop, :resettled=>@resettled }.merge(@forces.data)
    end

    [:gov, :gov_cubes, :french_cubes, :algerian_cubes, :troops, :police, :gov_bases, :french_troops, :french_police, :algerian_troops, :algerian_police,
     :fln, :guerrillas, :fln_bases, :fln_underground, :fln_active,
     :max_bases].each do |sym|
      define_method sym do @forces.send(sym) end
    end

    def city?; false; end
    def country?; false; end
    def border?; (@attributes & BORDER) == BORDER end
    def coastal?; (@attributes & COASTAL) == COASTAL end
    def mountain?; (@attributes & MOUNTAIN) == MOUNTAIN end
    def support?; @alignment == :support end
    def oppose?; @alignment == :oppose end
    def neutral?; @alignment == :neutral end
    def control; @forces.control end
    def uncontrolled?; @forces.control == :uncontrolled end
    def fln_control?; @forces.control == :FLN end
    def gov_control?; @forces.control == :GOV end
    def has_terror?; terror > 0 end
    def has_gov?; not gov_bases_0? or not gov_cubes_0? end
    def has_fln?; not fln_bases_0? or fln > 0 end
    def gov_bases_0?; gov_bases == 0 end
    def fln_bases_0?; fln_bases == 0 end
    def gov_bases_1m?; gov_bases > 0 end
    def fln_bases_1m?; fln_bases > 0 end
    def pop0?; pop == 0 end
    def gov_cubes_0?; gov_cubes == 0 end
    def add t, n=1; @forces.add t, n end
    def fln_u_1l?; fln_underground < 2 end
    def fln_u_0?; fln_underground == 0 end
    def fln_u_1m?; fln_underground > 0 end
    def fln_u_2m?; fln_underground > 1 end
    def fln_u_3m?; fln_underground > 2 end
    def resettle!
      raise "can't resettle a country " if country?
      raise "can't resettle a sector with a population > 1" if @pop != 1
      @pop = 0
      @resettled = true
    end

    def shift towards
      if towards == :oppose
        raise "can't shift towards oppose" if oppose?
        @alignment = (support? ? :neutral : :oppose)
      end
      if towards == :support
        raise "can't shift towards support" if support?
        @alignment = (oppose? ? :neutral : :support)
      end
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

    def initialize n, w
      super n, w, 0, 1, MOUNTAIN|BORDER|COASTAL
      @descr += " #{@independant ? 'Independant' : 'French'}"
    end
    def add_gov_base n=1; raise "no gov bases allowed in #@name"  end
    def country?; true; end
  end


  class Board

    FRANCE_TRACK=['A','B','C','D','E','F'].freeze

    attr_reader :spaces_h, :spaces, :sectors, :cities, :countries

    [:commitment, :gov_resources, :fln_resources, :resettled_sectors, :france_track, :border_zone_track].each do |sym|
      define_method sym do instance_variable_get("@#{sym}").v end
    end

    [:gov_bases, :french_troops, :french_police, :algerian_troops, :algerian_police, :fln_bases, :fln_underground].each do |sym|
      define_method "available_#{sym}" do @available.send(sym) end
      # define_method "casualties_#{sym}" do @casualties.send(sym) end
      # define_method "out_of_play_#{sym}" do @out_of_play.send(sym) end
    end

    def initialize
      @names = []
      @spaces_h = {}
      @capabilities = []
      @resettled_sectors = 0
      @available = Box.new :available
      @casualties = Box.new :casualties
      @out_of_play = Box.new :out_of_play
      @fln_resources = Track.new 50
      @gov_resources = Track.new 50
      @commitment = Track.new 50
      @support_commitment = Track.new 50
      @opposition_bases = Track.new 50
      @france_track = Track.new 5
      @border_zone_track = Track.new 4
      feed
      @spaces = @spaces_h.values
      @sectors = @spaces.select { |s| not s.country? }
      @cities = @spaces.select { |s| s.city? }
      @countries = @spaces.select { |s| s.country? }
    end

    def transfer n, what, from, to, towhat=nil
      towhat = what if towhat.nil?
      from = get_var from if from.is_a? Symbol
      to = get_var to if to.is_a? Symbol
      from.add what, -n
      to.add towhat, n
      { :n => n, :what => what, :from=>from, :to => to, :towhat=> towhat }
    end

    def terror where, n
      where.terror += n
    end

    def shift where, towards, n=1
      n.times do
        where.shift towards
      end
    end

    def shift_track what, dt
      case what
      when :fln_resources; @fln_resources.clamp dt
      when :gov_resources; @gov_resources.clamp dt
      when :commitment; @commitment.clamp dt
      when :france_track; @france_track.shift dt
      when :border_zone_track; @border_zone_track.shift dt
      else
        raise "shift_track: '#{what}'unknown"
      end
    end

    def has where=:spaces, &block
      r = search &block
      r.length > 0
    end

    def search where=:spaces, &block
      send(where).select &block
    end

    def count where=:spaces, &block
      send(where).inject(0) {|i,s| i + block.call(s) }
    end

    def resettle sector
      @spaces_h[sector].resettle!
      @resettled_sectors += 1
    end

    def compute_victory_points
      values = [@support_commitment.v, @opposition_bases.v]
      @opposition_bases.v = 0
      @support_commitment.v =  @commitment.v
      @spaces_h.each do |n,s|
        @opposition_bases.clamp s.fln_bases
        @opposition_bases.clamp s.pop if s.alignment == :oppose
        @support_commitment.clamp s.pop if s.alignment == :support
      end
      values << @support_commitment.v << @opposition_bases.v
    end

    def data
      h = { }
      [:gov_resources, :fln_resources, :commitment, :support_commitment, :opposition_bases,
       :france_track, :border_zone_track, :available, :casualties, :out_of_play].each do |sym|
        h[sym] = instance_variable_get("@#{sym}").data
      end
      h[:resettled_sectors] = @resettled_sectors
      h[:capabilities] = @capabilities
      h[:spaces] = @spaces_h.inject([])do |a,(k,s)| a << s.data end
      h
    end

    def load scenario
      case scenario
      when :short; short
      when :medium; medium
      when :full; full
      else raise "unknown scenario : #{scenario}"
      end
    end

    private

    def get_var sym
      case sym
      when :available; return @available
      when :casualties; return @casualties
      when :out_of_play; return @out_of_play
      else
        raise "unknown Board variable named #{sym}"
      end
    end

    def add k, *args
      s = k.new *args
      # puts s
      @names << s.name
      @spaces_h[s.name] = s
    end

    def adjacents i, *args
      @spaces_h[@names[i]].adjacents = args
      # @spaces_h[@names[i]].adjacents = args.map { |i| @names[i] }
      # puts @spaces_h[@names[i]]
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
      add Country, 'Moroco', 0                                  # 28
      add Country, 'Tunisia', 1                                 # 29
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
      s = @spaces_h[@names[i]]
      s.alignment = align unless align.nil?
      s.add :gov_base, h[:govb] if h.has_key? :govb
      s.add :fln_base, h[:flnb] if h.has_key? :flnb
      s.add :french_troops, h[:ft] if h.has_key? :ft
      s.add :french_police, h[:fp] if h.has_key? :fp
      s.add :algerian_troops, h[:at] if h.has_key? :at
      s.add :algerian_police, h[:ap] if h.has_key? :ap
      s.add :fln_underground, h[:fln] if h.has_key? :fln
      # puts s
    end

    def short
      @resettled_sectors = 0
      @commitment.v = 15
      @fln_resources.v = 15
      @gov_resources.v = 20
      @france_track.v = 4
      @border_zone_track.v = 3
      @out_of_play.fln_underground = 5
      @available.gov_bases = 2
      @available.french_police = 4
      @available.fln_bases = 7
      @available.fln_underground = 8
      resettle 'Setif'
      resettle 'Tlemcen'
      resettle 'Bordj Bou Arreridj'
      raise "resettled sectors not counted" if @resettled_sectors != 3
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
      compute_victory_points
      raise "wrong opposition + bases" if @opposition_bases.v != 19
      raise "wrong support + commitment" if @support_commitment.v != 22
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
    # b.spaces.select{ |s| s.coastal? }.each { |s| puts s.name }
    raise "coastal sectors error" if b.spaces.select{ |s| s.coastal? }.size != 14
    # puts '--- not Mountain'
    # b.spaces.select{ |s| not s.mountain? }.each { |s| puts s.name }
    raise "not moauntain sectors error" if b.spaces.select{ |s| not s.mountain? }.size != 9
    # puts '--- Border'
    # b.spaces.select{ |s| s.border? }.each { |s| puts s.name }
    raise "border sectors error" if b.spaces.select{ |s| s.border? }.size != 9
    # puts '--- City'
    # b.spaces.select{ |s| s.city? }.each { |s| puts s.name }
    raise "city sectors error" if b.spaces.select{ |s| s.city? }.size != 3
    [[0,11],[1,9],[2,9],[3,1]].each do |p,n|
      # puts "--- Population #{p}"
      # b.spaces.select{ |s| s.pop==p }.each { |s| puts s.name }
      raise "population #{p} error" if b.spaces.select{ |s| s.pop==p}.size != n
    end
    raise "sectors count wrong" if b.sectors.size != 28
  end

  def check_forces what, b, v
    sup, opp, gov, fln = 0, 0, 0, 0
    ft, fp, at, ap, g = 0, 0, 0, 0, 0
    gb, fb = 0, 0
    b.spaces.each do |s|
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
