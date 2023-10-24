# frozen_string_literal: true

class Sector
  attr_reader :name
  attr_writer :data

  def initialize(data = { name: 'sector', pop: 0, fln_bases: 0, fln_active: 0, fln_underground: 0, gov_cubes: 0, independent: true, support: false, terror: 0 })
    @name = data[:name] || 'sector'
    @data = data
  end

  def sector?
    @name == 'sector'
  end

  def city?
    @name == 'city'
  end

  def country?
    @name == 'country'
  end

  def max_bases
    3
  end

  def independent?
    @data[:independent]
  end

  def support?
    @data[:support]
  end

  def terror
    @data[:terror]
  end

  def pop
    @data[:pop] || 0
  end

  def guerrillas
    fln_active + fln_underground
  end

  def fln_bases
    @data[:fln_bases] || 0
  end

  def fln_active
    @data[:fln_active] || 0
  end

  def fln_underground
    @data[:fln_underground] || 0
  end

  def fln
    fln_active + fln_underground + fln_bases
  end

  def gov_cubes
    @data[:gov_cubes] || 0
  end

  def gov_bases
    @data[:gov_bases] || 0
  end

  def gov
    gov_cubes + gov_bases
  end
end

class Board
  attr_reader :sector, :spaces
  attr_accessor :fln_resources, :available_fln_underground, :available_fln_bases

  def initialize
    @fln_resources = 0
    @available_fln_bases = 1
    @available_fln_underground = 0
    @sector = Sector.new
    @spaces = []
  end

  def has(&block)
    block.call(@sector)
  end

  def count(&block)
    block.call(@sector)
  end
end
