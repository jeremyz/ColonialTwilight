#! /usr/bin/env ruby
# frozen_string_literal: true

# rubocop:disable Style/AccessorGrouping
# rubocop:disable Style/ParallelAssignment
# rubocop:disable Layout/ArrayAlignment

module ColonialTwilight
  # pieces container
  class Forces
    attr_accessor :algerian_troops, :algerian_police
    attr_accessor :french_troops, :french_police
    attr_accessor :fln_underground, :fln_active
    attr_accessor :fln_bases, :gov_bases
    attr_reader :max_bases, :control

    def initialize(kind)
      @algerian_troops, @algerian_police = 0, 0
      @french_troops, @french_police, @gov_bases = 0, 0, 0
      @fln_underground, @fln_active, @fln_bases = 0, 0, 0
      @max_bases = nil
      @control = :uncontrolled
      @max_bases = 2 if %i[Country Sector].include? kind
      _instance_variables(kind)&.each do |sym|
        instance_variable_set(sym, nil)
      end
    end

    private

    def _instance_variables(kind)
      case kind
      when :available then %i[@control @fln_active]
      when :casualties then %i[@control @fln_active @fln_bases]
      when :out_of_play then %i[@control @algerian_troops @algerian_police @fln_active @fln_bases]
      when :Country then %i[@control @algerian_troops @algerian_police @french_troops @french_police @gov_bases]
      when :Sector then nil
      end
    end

    public

    alias to_s inspect
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
      h = {}
      %i[algerian_troops algerian_police french_troops french_police
        fln_underground fln_active fln_bases gov_bases control].each do |sym|
        h[sym] = send(sym) unless send(sym).nil?
      end
      h
    end

    def bases
      (@gov_bases || 0) + (@fln_bases || 0)
    end

    def fln
      guerrillas + (@fln_bases || 0)
    end

    def guerrillas
      (@fln_underground || 0) + (@fln_active || 0)
    end

    def gov
      gov_cubes + (@gov_bases || 0)
    end

    def gov_cubes
      french_cubes + algerian_cubes
    end

    def french_cubes
      (@french_troops || 0) + (@french_police || 0)
    end

    def algerian_cubes
      (@algerian_troops || 0) + (@algerian_police || 0)
    end

    def troops
      (@french_troops || 0) + (@algerian_troops || 0)
    end

    def police
      (@french_police || 0) + (@algerian_police || 0)
    end

    def add(type, num = 1)
      case type
      when :french_troops then @french_troops += num
      when :french_police then @french_police += num
      when :algerian_troops then @algerian_troops += num
      when :algerian_police then @algerian_police += num
      when :fln_underground then @fln_underground += num
      when :fln_active then @fln_active += num
      when :gov_base then add_base(:gov_base, num)
      when :fln_base then add_base(:fln_base, num)
      else
        raise "unknown force type : #{type}"
      end
      update_control
    end

    private

    def add_base(type, num = 1)
      if !@max_bases.nil? && (bases + num) > @max_bases
        raise "too much bases in #{@name} (#{bases} + #{num}) > #{@max_bases}"
      end

      @gov_bases += num if type == :gov_base
      @fln_bases += num if type == :fln_base
    end

    def update_control
      return if @control.nil?

      @control = (
          case gov <=> fln
          when  0 then :uncontrolled
          when  1 then :GOV
          when -1 then :FLN
          end
        )
    end
  end

  # a point Track
  class Track
    attr_accessor :v

    def initialize(max)
      @v = 0
      @max = max
    end

    def shift(val)
      w = @v + val
      return false if w.negative? || w > @max

      @v = w
      true
    end

    def clamp(val)
      @v = (@v + val).clamp(0, @max)
    end

    def data
      @v
    end
  end

  # a piece holding Box
  class Box < Forces
    attr_reader :name

    def initialize(sym)
      super sym
      @name = sym
    end
  end

  # a map Sector
  class Sector
    MOUNTAIN = 1
    COASTAL = 2
    BORDER = 4

    attr_reader :wilaya, :sector, :name, :resettled
    attr_accessor :pop, :terror, :adjacents
    attr_accessor :alignment

    def initialize(name, wilaya, sector, pop, attrs = 0)
      @name = name
      @wilaya = wilaya
      @sector = sector
      @pop = pop
      @attrs = attrs
      @alignment = :neutral
      @resettled = false
      @terror = 0
      @forces = Forces.new self.class.name.split('::')[-1].to_sym
      _compute_strings
    end

    private

    def _compute_strings
      @terrain = %i[mountain coastal border].map { |s| send("#{s}?") ? s : nil }.reject(&:nil?).join('/')
      @descr = "#{self.class.name} #{@name} #{@wilaya.nil? ? '' : @wilaya}" + (@sector.nil? ? '' : "-#{@sector}")
    end

    public

    def to_s
      @name
    end

    def inspect
      "#{@descr} #{@terrain}
      control    : #{@forces.control}
      alignment  : #{@alignment}
      terror     : #{@terror}
      population : #{@pop}#{@resettled ? ' resettled' : ''}
      forces     : #{@forces}
      adjs       : #{@adjacents}"
    end

    def data
      { name: @name, alignment: @alignment, terror: @terror, pop: @pop, resettled: @resettled }.merge(@forces.data)
    end

    %i[gov gov_cubes french_cubes algerian_cubes troops police gov_bases
      french_troops french_police algerian_troops algerian_police
      fln guerrillas fln_bases fln_underground fln_active max_bases].each do |sym|
      define_method(sym) { @forces.send(sym) }
    end

    def city?
      false
    end

    def country?
      false
    end

    def border?
      (@attrs & BORDER) == BORDER
    end

    def coastal?
      (@attrs & COASTAL) == COASTAL
    end

    def mountain?
      (@attrs & MOUNTAIN) == MOUNTAIN
    end

    def support?
      @alignment == :support
    end

    def oppose?
      @alignment == :oppose
    end

    def neutral?
      @alignment == :neutral
    end

    def control
      @forces.control
    end

    def uncontrolled?
      @forces.control == :uncontrolled
    end

    def fln_control?
      @forces.control == :FLN
    end

    def gov_control?
      @forces.control == :GOV
    end

    def has_terror?
      terror.positive?
    end

    def has_gov?
      !gov_bases_0? || !gov_cubes_0?
    end

    def has_fln?
      !fln_bases_0? or fln.positive?
    end

    def gov_bases_0?
      gov_bases.zero?
    end

    def fln_bases_0?
      fln_bases.zero?
    end

    def gov_bases_1m?
      gov_bases.positive?
    end

    def fln_bases_1m?
      fln_bases.positive?
    end

    def pop0?
      pop.zero?
    end

    def gov_cubes_0?
      gov_cubes.zero?
    end

    def add(type, num = 1)
      @forces.add(type, num)
    end

    def fln_u_1l?
      fln_underground < 2
    end

    def fln_u_0?
      fln_underground.zero?
    end

    def fln_u_1m?
      fln_underground.positive?
    end

    def fln_u_2m?
      fln_underground > 1
    end

    def fln_u_3m?
      fln_underground > 2
    end

    def resettle!
      raise "can't resettle a country " if country?
      raise "can't resettle a sector with a population > 1" if @pop != 1

      @pop = 0
      @resettled = true
    end

    def shift(towards)
      if towards == :oppose
        raise "can't shift towards oppose" if oppose?

        @alignment = (support? ? :neutral : :oppose)
      elsif towards == :support
        raise "can't shift towards support" if support?

        @alignment = (oppose? ? :neutral : :support)
      end
    end
  end

  # a City Sector
  class City < Sector
    def initialize(name, wilaya, pop, attrs = 0)
      super name, wilaya, 0, pop, attrs
    end

    def city?
      true
    end
  end

  # a Country Sector
  class Country < Sector
    attr_reader :independant

    def initialize(name, wilaya)
      super(name, wilaya, nil, 1, MOUNTAIN | BORDER | COASTAL)
      @descr += " #{@independant ? 'Independant' : 'French'}"
    end

    def add_gov_base
      raise "no gov bases allowed in #{@name}"
    end

    def country?
      true
    end
  end

  # the game Board
  class Board
    FRANCE_TRACK = %w[A B C D E F].freeze

    attr_reader :spaces_h, :spaces, :sectors, :cities, :countries

    %i[commitment gov_resources fln_resources resettled_sectors france_track border_zone_track].each do |sym|
      define_method(sym) { instance_variable_get("@#{sym}").v }
    end

    %i[gov_bases french_troops french_police algerian_troops algerian_police fln_bases fln_underground].each do |sym|
      define_method("available_#{sym}") { @available.send(sym) }
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
      set_sectors
      set_adjacents
      @spaces = @spaces_h.values
      @sectors = @spaces.reject(&:country?)     # FIXME
      @cities = @spaces.select(&:city?)         # FIXME
      @countries = @spaces.select(&:country?)   # FIXME
    end

    def transfer(num, what, from, to, towhat = nil)
      towhat = what if towhat.nil?
      from = get_var from if from.is_a? Symbol
      to = get_var to if to.is_a? Symbol
      from.add what, -num
      to.add towhat, num
      { nn: num, what: what, from: from, to: to, towhat: towhat }
    end

    def terror(where, num)
      where.terror += num
    end

    def shift(where, towards, num = 1)
      num.times { where.shift towards }
    end

    def shift_track(what, amount)
      case what
      when :fln_resources then @fln_resources.clamp amount
      when :gov_resources then @gov_resources.clamp amount
      when :commitment then @commitment.clamp amount
      when :france_track then @france_track.shift amount
      when :border_zone_track then @border_zone_track.shift amount
      else
        raise "shift_track: '#{what}'unknown"
      end
    end

    def has(where = :spaces, &block)
      r = search(where, &block)
      r.length.positive?
    end

    def search(where = :spaces, &block)
      send(where).select(&block)
    end

    def count(where = :spaces, &block)
      send(where).inject(0) { |i, s| i + block.call(s) }
    end

    def resettle(sector)
      @spaces_h[sector].resettle!
      @resettled_sectors += 1
    end

    def compute_victory_points
      values = [@support_commitment.v, @opposition_bases.v]
      @opposition_bases.v = 0
      @support_commitment.v = @commitment.v
      @spaces_h.each do |_n, s|
        @opposition_bases.clamp s.fln_bases
        @opposition_bases.clamp s.pop if s.alignment == :oppose
        @support_commitment.clamp s.pop if s.alignment == :support
      end
      values << @support_commitment.v << @opposition_bases.v
    end

    def data
      h = {}
      %i[gov_resources fln_resources commitment support_commitment opposition_bases
        france_track border_zone_track available casualties out_of_play].each do |sym|
        h[sym] = instance_variable_get("@#{sym}").data
      end
      h[:resettled_sectors] = @resettled_sectors
      h[:capabilities] = @capabilities
      h[:spaces] = @spaces_h.inject([]) { |a, (_k, s)| a << s.data }
      h
    end

    def load(scenario)
      case scenario
      when :short then short
      when :medium then medium
      when :full then full
      else raise "unknown scenario : #{scenario}"
      end
    end

    private

    def get_var(sym)
      case sym
      when :available then @available
      when :casualties then @casualties
      when :out_of_play then @out_of_play
      else
        raise "unknown Board variable named #{sym}"
      end
    end

    def add(kls, *args)
      s = kls.new(*args)
      # puts s
      @names << s.name
      @spaces_h[s.name] = s
    end

    def adjacents(idx, *args)
      @spaces_h[@names[idx]].adjacents = args
      # @spaces_h[@names[idx]].adjacents = args.map { |i| @names[i] }
      # puts @spaces_h[@names[idx]]
    end

    def set_sectors
      mountain = Sector::MOUNTAIN
      border = Sector::BORDER
      coastal = Sector::COASTAL
      add Sector, 'Barika', 'I', 1, 1, mountain
      add Sector, 'Batna', 'I', 2, 0, mountain
      add Sector, 'Biskra', 'I', 3, 0, border
      add Sector, 'Oum El Bouaghi', 'I', 4, 0, mountain
      add Sector, 'Tebessa', 'I', 5, 1, mountain | border
      add Sector, 'Negrine', 'I', 6, 0, mountain | border
      add City, 'Constantine', 'II', 2
      add Sector, 'Setif', 'II', 1, 1, mountain | coastal
      add Sector, 'Philippeville', 'II', 2, 2, mountain | coastal
      add Sector, 'Souk Ahras', 'II', 3, 2, coastal | border
      add Sector, 'Tizi Ouzou', 'III', 1, 2, mountain | coastal
      add Sector, 'Bordj Bou Arreridj', 'III', 2, 1, mountain
      add Sector, 'Bougie', 'III', 3, 2, mountain | coastal
      add City, 'Algiers', 'IV', 3, coastal
      add Sector, 'Medea', 'IV', 1, 2, mountain | coastal
      add Sector, 'Orleansville', 'IV', 2, 2, mountain | coastal
      add City, 'Oran', 'V', 2, coastal
      add Sector, 'Mecheria', 'V', 1, 0, mountain | border
      add Sector, 'Tlemcen', 'V', 2, 1, border | coastal
      add Sector, 'Sidi Bel Abbes', 'V', 3, 1, coastal
      add Sector, 'Mostaganem', 'V', 4, 2, mountain | coastal
      add Sector, 'Saida', 'V', 5, 0, mountain
      add Sector, 'Mascara', 'V', 6, 0, mountain
      add Sector, 'Tiaret', 'V', 7, 0, mountain
      add Sector, 'Ain Sefra', 'V', 8, 0, border
      add Sector, 'Laghouat', 'V', 9, 0
      add Sector, 'Sidi Aissa', 'VI', 1, 0, mountain
      add Sector, 'Ain Oussera', 'VI', 2, 1, mountain
      add Country, 'Moroco', 0
      add Country, 'Tunisia', 1
    end

    def set_adjacents
      adjacents  0, 1, 2, 3, 7, 8, 11, 26
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
      adjacents 29, 2, 4, 5, 9
    end

    def set_sector(idx, opts, align = nil)
      s = @spaces_h[@names[idx]]
      s.alignment = align unless align.nil?
      %i[gov_base fln_base french_troops french_police algerian_troops algerian_police
        fln_underground].each { |sym| s.add(sym, opts[sym]) if opts.key? sym }
      # s.add :gov_base, opts[:govb] if opts.key? :govb
      # s.add :fln_base, opts[:flnb] if opts.key? :flnb
      # s.add :french_troops, opts[:ft] if opts.key? :ft
      # s.add :french_police, opts[:fp] if opts.key? :fp
      # s.add :algerian_troops, opts[:at] if opts.key? :at
      # s.add :algerian_police, opts[:ap] if opts.key? :ap
      # s.add :fln_underground, opts[:fln] if opts.key? :fln
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
      raise 'resettled sectors not counted' if @resettled_sectors != 3

      set_sector  0, { algerian_police: 1, fln_underground: 1 }, :oppose
      set_sector  2, { french_police: 1 }
      set_sector  4, { algerian_police: 1, fln_underground: 1 }, :oppose
      set_sector  5, { french_police: 1 }
      set_sector  6, { french_police: 1 }, :support
      set_sector  7, { fln_underground: 1 }
      set_sector  8, { french_troops: 4, algerian_police: 1, gov_base: 1 }
      set_sector  9, { french_troops: 1, algerian_police: 1, gov_base: 1, fln_underground: 1, fln_base: 1 }, :oppose
      set_sector 10, { french_police: 1, fln_underground: 1, fln_base: 1 }, :oppose
      set_sector 11, { french_police: 1 }
      set_sector 12, { french_police: 1, fln_underground: 1, fln_base: 1 }, :oppose
      set_sector 13, { french_troops: 4, algerian_troops: 1, french_police: 1 }, :support
      set_sector 14, { algerian_troops: 1, gov_base: 1 }
      set_sector 15, { french_police: 1, algerian_police: 1, fln_underground: 1, fln_base: 1 }, :oppose
      set_sector 16, { algerian_troops: 1, french_police: 1, algerian_police: 1 }, :support
      set_sector 17, { french_police: 1, algerian_police: 1 }
      set_sector 18, { french_police: 2, fln_underground: 1 }
      set_sector 19, { french_police: 1, gov_base: 1 }
      set_sector 20, { french_police: 1 }
      set_sector 22, { french_police: 1 }
      set_sector 23, { french_police: 1 }
      set_sector 24, { french_police: 1 }
      set_sector 27, {}, :oppose
      set_sector 28, { fln_underground: 4, fln_base: 2 }
      set_sector 29, { fln_underground: 5, fln_base: 2 }
      compute_victory_points
      raise "wrong opposition + bases #{@opposition_bases.v} != 19" if @opposition_bases.v != 19
      raise "wrong support + commitment : #{@support_commitment.v} != 22" if @support_commitment.v != 22
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
  def check(board)
    # puts '--- Coastal'
    # board.spaces.select{ |s| s.coastal? }.each { |s| puts s.name }
    raise 'coastal sectors error' if board.spaces.select(&:coastal?).size != 14
    # puts '--- not Mountain'
    # board.spaces.select{ |s| not s.mountain? }.each { |s| puts s.name }
    raise 'not moauntain sectors error' if board.spaces.reject(&:mountain?).size != 9
    # puts '--- Border'
    # board.spaces.select{ |s| s.border? }.each { |s| puts s.name }
    raise 'border sectors error' if board.spaces.select(&:border?).size != 9
    # puts '--- City'
    # board.spaces.select{ |s| s.city? }.each { |s| puts s.name }
    raise 'city sectors error' if board.spaces.select(&:city?).size != 3

    [[0, 11], [1, 9], [2, 9], [3, 1]].each do |p, n|
      # puts "--- Population #{p}"
      # board.spaces.select{ |s| s.pop==p }.each { |s| puts s.name }
      raise "population #{p} error" if board.spaces.select { |s| s.pop == p }.size != n
    end
    raise 'sectors count wrong' if board.sectors.size != 28
  end

  def check_forces what, board, vals
    sup, opp, gov, fln = 0, 0, 0, 0
    ft, fp, at, ap, g = 0, 0, 0, 0, 0
    gb, fb = 0, 0
    board.spaces.each do |s|
      sup += 1 if s.alignment == :support
      opp += 1 if s.alignment == :oppose
      gov += 1 if s.control == :GOV
      fln += 1 if s.control == :FLN
      unless s.country?
        ft += s.french_troops
        fp += s.french_police
        at += s.algerian_troops
        ap += s.algerian_police
        gb += s.gov_bases
      end
      g += s.fln_underground
      fb += s.fln_bases
    end
    raise "wrong support #{sup} != #{vals[0]}" if sup != vals[0]
    raise "wrong oppose #{opp} != #{vals[1]}" if opp != vals[1]
    raise "wrong GOV control #{gov} != #{vals[2]}" if gov != vals[2]
    raise "wrong FLN control #{fln} != #{vals[3]}" if fln != vals[3]
    raise "wrong french troops #{ft} != #{vals[4]}" if ft != vals[4]
    raise "wrong french police  #{fp} != #{vals[5]}" if fp != vals[5]
    raise "wrong algerian troops #{at} != #{vals[6]}" if at != vals[6]
    raise "wrong algerian police #{ap} != #{vals[7]}" if ap != vals[7]
    raise "wrong Guerrillas #{g} != #{vals[8]}" if g != vals[8]
    raise "wrong GOV bases #{gb} != #{vals[9]}" if gb != vals[9]
    raise "wrong FLN bases #{fb} != #{vals[10]}" if fb != vals[10]
  end

  b = ColonialTwilight::Board.new
  puts 'check'
  check b
  b.load :short
  check_forces 'short', b, [3, 7, 16, 3, 9, 17, 3, 7, 17, 4, 8]
  puts 'ok'
end
