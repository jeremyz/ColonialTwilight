#! /usr/bin/env ruby
# frozen_string_literal: true

require_relative 'board/forces'
require_relative 'board/spaces'
require_relative 'board/setup'
require_relative 'board/scenario'

module ColonialTwilight
  class Board
    FRANCE_TRACK = %w[A B C D E F].freeze

    TRACKS = %i[support_commitment opposition_bases fln_resources
                gov_resources commitment france_track border_zone_track].freeze

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

    include Setup
    include Scenario

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
      setup
    end

    def inspect
      'Board'
    end

    def load(scenario)
      case scenario
      when :short then short_scenario
      when :medium then medium_scenario
      when :full then full_scenario
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
      num.times { space.shift(towards) }
    end

    def shift_track(what, amount)
      raise "unknown track : #{what}" unless TRACKS.include?(what)

      instance_variable_get("@#{what}").shift(amount)
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
  end
end
