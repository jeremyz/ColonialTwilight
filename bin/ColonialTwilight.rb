#! /usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'
require 'colonial_twilight'

class OptParser
  class Options
    attr_accessor :debug, :verbose, :ui, :clearscreen

    def initialize
      @debug = 0
      @verbose = false
      @ui = :cli
      @clearscreen = false
    end

    def define_options(parser)
      parser.banner = 'Usage: ColonialTwilight.rb [options]'
      parser.separator ''
      parser.separator 'Specific options:'

      add_debug(parser)
      add_verbose(parser)
      add_gui(parser)
      add_clearscreen(parser)

      parser.separator ''
      parser.separator 'Common options:'
      parser.on_tail('-h', '--help', 'Show this message') do
        puts parser
        exit
      end
      parser.on_tail('--version', 'Show version') do
        puts ColonialTwilight::VERSION
        exit
      end
    end

    def add_debug(parser)
      parser.on('-d', '--debug', 'Run with FLN bot debug messages') { @debug += 1 }
    end

    def add_verbose(parser)
      parser.on('-v', '--verbose', 'Run more verbose ui') { @verbose = true }
    end

    def add_gui(parser)
      parser.on('-g', '--gui', 'Run in gui mode') do
        @ui = :gui
        puts 'gui is not implemented yet ...'
        exit
      end
    end

    def add_clearscreen(parser)
      parser.on('-c', '--clearscreen', 'Clear screen before each player turn') { @clearscreen = true }
    end
  end

  def parse(args)
    @options = Options.new
    @parser = OptionParser.new do |parser|
      @options.define_options(parser)
      parser.parse!(args)
    end
    @options
  end
  attr_reader :parser, :options
end

options = OptParser.new.parse(ARGV)

require 'colonial_twilight/game'
game = ColonialTwilight::Game.new options
game.launch
