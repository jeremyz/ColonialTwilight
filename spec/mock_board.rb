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
    @data[:support] || false
  end

  def oppose?
    @data[:oppose] || false
  end

  def neutral?
    @data[:neutral] || false
  end

  def terror
    @data[:terror] || 0
  end

  def terror?
    terror.positive?
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
    @data[:gov_cubes] || (french_cubes + algerian_cubes)
  end

  def gov_bases
    @data[:gov_bases] || 0
  end

  def gov
    gov_cubes + gov_bases
  end

  def troops
    @data[:troops] || (french_troops + algerian_troops)
  end

  def police
    @data[:police] || (french_police + algerian_police)
  end

  def french_cubes
    french_police + french_troops
  end

  def french_police
    @data[:french_police] || 0
  end

  def french_troops
    @data[:french_troops] || 0
  end

  def algerian_cubes
    algerian_police + algerian_troops
  end

  def algerian_police
    @data[:algerian_police] || 0
  end

  def algerian_troops
    @data[:algerian_troops] || 0
  end

  def fln_control?
    fln > gov
  end

  def gov_control?
    gov > fln
  end
end

class Board
  attr_reader :sector, :spaces
  attr_accessor :fln_resources, :available_fln_underground, :available_fln_bases, :france_track

  def initialize
    @fln_resources = 0
    @france_track = 0
    @available_fln_bases = 1
    @available_fln_underground = 0
    @sector = Sector.new
    @spaces = []
  end

  def apply(action, keep)
    @fln_resources -= action.cost
    spaces.delete(action.space) unless keep
  end

  def has(&block)
    block.call(@sector)
  end

  def search(&block)
    @spaces.select(&block)
  end

  def count(&block)
    block.call(@sector)
  end
end

class Options
  def debug
    @debug || 0
  end
end

class Game
  attr_reader :action, :actions, :current_card
  attr_accessor :board, :options, :keep

  def initialize
    @actions = []
    @board = Board.new
    @options = Options.new
    @keep = false
  end

  def set(hash)
    @board.spaces << Sector.new(hash)
  end

  def d6
    3
  end

  def apply(_faction, action)
    if @options.debug.positive?
      puts '** _apply'
      puts action.inspect
    end
    @action = action
    @actions << action
    @board.apply(action, @keep)
    true
  end
end
