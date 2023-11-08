#! /usr/bin/env ruby
# frozen_string_literal: true

require 'colonial_twilight/forces'

module ColonialTwilight
  class Track
    attr_accessor :v

    def initialize(max)
      @v = 0
      @max = max
    end

    def shift(val)
      @v += val
      raise "out of track #{@v}" if @v.negative? || @v > @max
      @v
    end

    def clamp(val)
      @v = (@v + val).clamp(0, @max)
    end

    def data
      @v
    end
  end

  class Box < Forces
  end

  class Sector
    MOUNTAIN = 1
    COASTAL = 2
    BORDER = 4

    attr_reader :wilaya, :sector, :name, :resettled
    attr_accessor :pop, :terror, :adjacents, :alignment

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
      @descr = "#{@name} #{self.class.name.split('::')[-1]}#{number}"
    end

    def number
      return '' if @wilaya.nil? && @sector.nil?

      @descr = "(#{@wilaya}-#{@sector})"
    end

    public

    def to_s
      @name
    end

    def inspect
      "\n#{@descr} : #{@terrain}
      population : #{@pop}#{@resettled ? ' resettled' : ''}
      control    : #{control}
      alignment  : #{@alignment}
      terror     : #{@terror}
      #{@forces}
      adjs       : #{@adjacents}"
    end

    def data
      { name: @name, alignment: @alignment, terror: @terror, pop: @pop, resettled: @resettled }.merge(@forces.data)
    end

    %i[gov gov_bases gov_cubes french_cubes algerian_cubes troops police
       french_troops french_police algerian_troops algerian_police
       fln fln_bases guerrillas fln_underground fln_active max_bases control].each do |sym|
      define_method(sym) { @forces.send(sym) }
    end

    def sector?
      true
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

    def terror?
      @terror.positive?
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

    def uncontrolled?
      control == :uncontrolled
    end

    def fln_control?
      control == :FLN
    end

    def gov_control?
      control == :GOV
    end

    def add(type, num = 1)
      @forces.add(type, num)
    end

    def shift_terror(num = 1)
      raise "terror cant be negative" if @terror.zero? and num.negative?

      @terror += num
    end

    def resettled?
      @resettled
    end

    def resettle!
      raise "can't resettle a country " if country?
      raise "can't resettle a sector with a population =! 1" if @pop != 1

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
      else
        raise "unknown shift direction : #{towards}"
      end
    end
  end

  class City < Sector
    def initialize(name, wilaya, pop, attrs = 0)
      super name, wilaya, 0, pop, attrs
    end

    def sector?
      false
    end

    def city?
      true
    end
  end

  # if independent, FLN may Rally, March and Extort in these Countries,
  # but their Population is never counted in the total Opposition
  class Country < Sector
    attr_reader :independent

    def initialize(name)
      super(name, nil, nil, 1, MOUNTAIN | BORDER | COASTAL)
      @independent = false
      @descr += ' : French'
    end

    def sector?
      false
    end

    def country?
      true
    end

    def independent?
      @independent
    end

    def independent!
      @independent = true
      @descr.gsub!(/French/, 'Independent')
      @independent
    end
  end
end
