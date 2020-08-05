#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

require 'optparse'

require 'colonial_twilight'

class OptParser

  class Options

    attr_accessor :verbose, :clearscreen

    def initialize
      @verbose = false
      @gui = false
      @clearscreen = false
    end

    def define_options(parser)
      parser.banner = "Usage: ColonialTwilight.rb [options]"
      parser.separator ""
      parser.separator "Specific options:"

      add_verbose(parser)
      add_gui(parser)
      add_clearscreen(parser)

      parser.separator ""
      parser.separator "Common options:"
      parser.on_tail("-h", "--help", "Show this message") do
        puts parser
        exit
      end
      parser.on_tail("--version", "Show version") do
        puts ColonialTwilight::VERSION
        exit
      end
    end

    def add_verbose(parser)
      parser.on("-v", "--[no-]verbose", "Run verbosely") do |v|
        @verbose = v
      end
    end
    def add_gui(parser)
      parser.on("-g", "--gui", "Run verbosely") do
        @gui = true
        puts "gui is not implemented yet ..."
        exit
      end
    end
    def add_clearscreen(parser)
      parser.on("-c", "--clearscreen", "Clear screen before each player turn") do |v|
        @clearscreen = true
      end
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

parser = OptParser.new
options = parser.parse(ARGV)

require 'colonial_twilight/cli'
game = ColonialTwilight::Cli.new options
game.start
