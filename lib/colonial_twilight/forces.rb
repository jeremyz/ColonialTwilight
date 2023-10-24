#! /usr/bin/env ruby
# frozen_string_literal: true

# rubocop:disable Style/AccessorGrouping
# rubocop:disable Style/ParallelAssignment

module ColonialTwilight
  class Forces
    attr_reader :name
    attr_reader :algerian_troops, :algerian_police
    attr_reader :french_troops, :french_police
    attr_reader :fln_underground, :fln_active
    attr_reader :fln_bases, :gov_bases
    attr_reader :max_bases, :control

    def initialize(sym)
      @name = sym
      @algerian_troops, @algerian_police = 0, 0
      @french_troops, @french_police, @gov_bases = 0, 0, 0
      @fln_underground, @fln_active, @fln_bases = 0, 0, 0
      @max_bases = nil
      @control = :uncontrolled
      @max_bases = 2 if %i[Country Sector].include? sym
      _variables_to_remove(sym)&.each do |s|
        instance_variable_set(s, nil)
      end
    end

    def init(data)
      data.each { |k, v| add(k, v) }
    end

    private

    def _variables_to_remove(sym)
      case sym
      when :available then %i[@control @fln_active]
      when :casualties then %i[@control @fln_active @fln_bases]
      when :out_of_play then %i[@control @algerian_troops @algerian_police @fln_active @fln_bases]
      when :Country then %i[@control @algerian_troops @algerian_police @french_troops @french_police]
      when :City then nil
      when :Sector then nil
      end
    end

    public

    def inspect
      "GOV bases: #{gov_bases}
        french troops: #{french_troops}
        french police: #{french_police}
        algerian troops: #{algerian_troops}
        algerian police: #{algerian_police}
      FLN bases: #{fln_bases}
        underground Guerrillas: #{fln_underground}
        active Guerrillas: #{fln_active}"
    end
    alias to_s inspect

    def data
      h = {}
      %i[algerian_troops algerian_police french_troops french_police gov_bases
         fln_underground fln_active fln_bases control].each do |sym|
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
      type = :fln_underground if name == :available && type == :fln_active
      case type
      when :french_troops then @french_troops += num
      when :french_police then @french_police += num
      when :algerian_troops then @algerian_troops += num
      when :algerian_police then @algerian_police += num
      when :fln_underground then @fln_underground += num
      when :fln_active then @fln_active += num
      when :gov_bases then add_base(type, num)
      when :fln_bases then add_base(type, num)
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

      @gov_bases += num if type == :gov_bases
      @fln_bases += num if type == :fln_bases
    end

    def update_control
      return nil if @control.nil?

      ctr = @control
      @control = (
          case gov <=> fln
          when  0 then :uncontrolled
          when  1 then :GOV
          when -1 then :FLN
          end
        )
      @control != ctr
    end
  end
end
