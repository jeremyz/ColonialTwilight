#! /usr/bin/env ruby
# frozen_string_literal: true

require 'colonial_twilight/spaces'

module ColonialTwilight
  class Board
    FRANCE_TRACK = %w[A B C D E F].freeze
    TRACKS = %i[support_commitment opposition_bases fln_resources gov_resources commitment france_track border_zone_track].freeze

    attr_reader :spaces

    %i[commitment gov_resources fln_resources france_track border_zone_track
       support_commitment opposition_bases].each do |sym|
      define_method(sym) { instance_variable_get("@#{sym}").v }
    end

    %i[gov_bases french_troops french_police algerian_troops algerian_police fln_bases fln_underground].each do |sym|
      define_method("available_#{sym}") { @available.send(sym) }
      # define_method "casualties_#{sym}" do @casualties.send(sym) end
      # define_method "out_of_play_#{sym}" do @out_of_play.send(sym) end
    end

    def initialize
      @spaces = []
      @capabilities = []
      @available = Box.new :available
      @casualties = Box.new :casualties
      @out_of_play = Box.new :out_of_play
      @support_commitment = Track.new 50
      @opposition_bases = Track.new 50
      @fln_resources = Track.new 50
      @gov_resources = Track.new 50
      @commitment = Track.new 50
      @france_track = Track.new 5
      @border_zone_track = Track.new 4
      set_spaces
      set_adjacents
    end

    def inspect
      'Board'
    end

    def load(scenario)
      case scenario
      when :short then short
      when :medium then medium
      when :full then full
      else raise "unknown scenario : #{scenario}"
      end
    end

    def by_name(name)
      @spaces.find { |s| s.name == name }
    end

    def sector
      @spaces.select(&:sector?)
    end
    alias sectors sector

    def city
      @spaces.select(&:city?)
    end
    alias cities city

    def country
      @spaces.select(&:country?)
    end
    alias countries country

    def has(where = :spaces, &block)
      !send(where).select(&block).empty?
    end

    def search(where = :spaces, &block)
      send(where).select(&block)
    end

    def count(where = :spaces, &block)
      send(where).inject(0) { |i, s| i + block.call(s) }
    end

    def compute_opposition_bases
      count { |s| s.oppose? ? s.pop : 0 } + count(&:fln_bases)
    end

    def compute_support_commitment
      count { |s| s.support? ? s.pop : 0 } + @commitment.v
    end

    def shift(space, towards, num = 1)
      num.times { space.shift towards }
    end

    def shift_track(what, amount)
      raise "unknown track : #{what}" unless TRACKS.include? what

      instance_variable_get("@#{what}").shift amount
    end

    def apply(action)
      action.steps.each do |step|
        case step[:kind]
        when :transfer then transfer(step)
        else raise "unknow action step #{step}"
        end
      end
    end

    # def terror(where, num)
    #   where.terror += num
    # end

    # def data
    #   h = {}
    #   %i[gov_resources fln_resources commitment support_commitment opposition_bases
    #     france_track border_zone_track available casualties out_of_play].each do |sym|
    #     h[sym] = instance_variable_get("@#{sym}").data
    #   end
    #   h[:capabilities] = @capabilities
    #   h[:spaces] = @spaces.inject([]) { |a, s| a << s.data }
    #   h
    # end

    private

    def transfer(data)
      src = get_obj(data[:src])
      dst = get_obj(data[:dst])
      src.add data[:what], -data[:num]
      dst.add flip?(data), data[:num]
    end

    def flip?(data)
      !data[:flip] ? data[:what] : data[:flip]
    end

    def get_obj(obj)
      return obj if obj.is_a? ColonialTwilight::Sector

      case obj
      when :available then @available
      when :casualties then @casualties
      when :out_of_play then @out_of_play
      else
        raise "unknown Board variable named #{obj}"
      end
    end

    def add(kls, *args)
      @spaces << kls.new(*args)
    end

    def set_spaces
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
      add Country, 'Morocco'
      add Country, 'Tunisia'
    end

    def adjacents(name, *args)
      by_name(name).adjacents = args
    end

    def set_adjacents
      adjacents 'Barika', 1, 2, 3, 7, 8, 11, 26
      adjacents 'Batna', 0, 2, 3, 5
      adjacents 'Biskra', 0, 1, 5, 25, 26, 29
      adjacents 'Oum El Bouaghi', 0, 1, 4, 5, 8, 9
      adjacents 'Tebessa', 3, 5, 9, 29
      adjacents 'Negrine', 1, 2, 3, 4, 29
      adjacents 'Constantine', 7, 8
      adjacents 'Setif', 0, 6, 8, 11, 12
      adjacents 'Philippeville', 0, 3, 7, 6, 9
      adjacents 'Souk Ahras', 3, 4, 8, 29
      adjacents 'Tizi Ouzou', 11, 12, 14
      adjacents 'Bordj Bou Arreridj', 0, 7, 10, 12, 14, 26
      adjacents 'Bougie', 7, 10, 11
      adjacents 'Algiers', 14
      adjacents 'Medea', 10, 11, 13, 15, 26, 27
      adjacents 'Orleansville', 14, 20, 23, 27
      adjacents 'Oran', 19
      adjacents 'Mecheria', 18, 21, 24, 28
      adjacents 'Tlemcen', 17, 19, 21, 28
      adjacents 'Sidi Bel Abbes', 16, 18, 20, 21, 22
      adjacents 'Mostaganem', 15, 19, 22, 23
      adjacents 'Saida', 17, 18, 19, 22, 24
      adjacents 'Mascara', 19, 20, 21, 23, 24
      adjacents 'Tiaret', 15, 20, 22, 24, 27
      adjacents 'Ain Sefra', 17, 21, 22, 23, 25, 27, 28
      adjacents 'Laghouat', 2, 24, 26, 27
      adjacents 'Sidi Aissa', 0, 2, 11, 14, 25, 27
      adjacents 'Ain Oussera', 14, 15, 23, 24, 25, 26
      adjacents 'Morocco', 17, 18, 24
      adjacents 'Tunisia', 2, 4, 5, 9
    end

    def resettle(name)
      by_name(name).resettle!
    end

    def set_space(idx, opts, align = nil)
      s = @spaces[idx]
      s.alignment = align unless align.nil?
      %i[gov_bases fln_bases french_troops french_police algerian_troops algerian_police
         fln_underground].each { |sym| s.add(sym, opts[sym]) if opts.key? sym }
    end

    def short
      @opposition_bases.v = 19
      @support_commitment.v = 22
      @commitment.v = 15
      @fln_resources.v = 15
      @gov_resources.v = 20
      @france_track.v = 4
      @border_zone_track.v = 3
      @out_of_play.init({ fln_underground: 5 })
      @available.init({ gov_bases: 2, french_police: 4, fln_bases: 7, fln_underground: 8 })
      resettle 'Setif'
      resettle 'Tlemcen'
      resettle 'Bordj Bou Arreridj'

      set_space  0, { algerian_police: 1, fln_underground: 1 }, :oppose
      set_space  2, { french_police: 1 }
      set_space  4, { algerian_police: 1, fln_underground: 1 }, :oppose
      set_space  5, { french_police: 1 }
      set_space  6, { french_police: 1 }, :support
      set_space  7, { fln_underground: 1 }
      set_space  8, { french_troops: 4, algerian_police: 1, gov_bases: 1 }
      set_space  9, { french_troops: 1, algerian_police: 1, gov_bases: 1, fln_underground: 1, fln_bases: 1 }, :oppose
      set_space 10, { french_police: 1, fln_underground: 1, fln_bases: 1 }, :oppose
      set_space 11, { french_police: 1 }
      set_space 12, { french_police: 1, fln_underground: 1, fln_bases: 1 }, :oppose
      set_space 13, { french_troops: 4, algerian_troops: 1, french_police: 1 }, :support
      set_space 14, { algerian_troops: 1, gov_bases: 1 }
      set_space 15, { french_police: 1, algerian_police: 1, fln_underground: 1, fln_bases: 1 }, :oppose
      set_space 16, { algerian_troops: 1, french_police: 1, algerian_police: 1 }, :support
      set_space 17, { french_police: 1, algerian_police: 1 }
      set_space 18, { french_police: 2, fln_underground: 1 }
      set_space 19, { french_police: 1, gov_bases: 1 }
      set_space 20, { french_police: 1 }
      set_space 22, { french_police: 1 }
      set_space 23, { french_police: 1 }
      set_space 24, { french_police: 1 }
      set_space 27, {}, :oppose
      set_space 28, { fln_underground: 4, fln_bases: 2 }
      set_space 29, { fln_underground: 5, fln_bases: 2 }
      spaces[28].independent!
      spaces[29].independent!
    end

    def medium
      raise 'MEDIUM scenario net implemented yet'
    end

    def full
      raise 'FULL scenario net implemented yet'
    end
  end
end
