#! /usr/bin/env ruby
# frozen_string_literal: true

# rubocop:disable Style/Documentation

require 'optparse'
require 'colonial_twilight'

class OptParser
  class Options
    attr_accessor :debug_bot, :clearscreen, :verbose

    def initialize
      @debug_bot = false
      @verbose = false
      @gui = false
      @clearscreen = false
    end

    def define_options(parser)
      parser.banner = 'Usage: ColonialTwilight.rb [options]'
      parser.separator ''
      parser.separator 'Specific options:'

      add_debug_bot(parser)
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

    def add_debug_bot(parser)
      parser.on('-d', '--debug_bot', 'Run with FLN bot debug messages') do |v|
        @debug_bot = v
      end
    end

    def add_verbose(parser)
      parser.on('-v', '--verbose', 'Run more verbose ui') do |_v|
        @verbose = true
      end
    end

    def add_gui(parser)
      parser.on('-g', '--gui', 'Run in gui mode') do
        @gui = true
        puts 'gui is not implemented yet ...'
        exit
      end
    end

    def add_clearscreen(parser)
      parser.on('-c', '--clearscreen', 'Clear screen before each player turn') do |_v|
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
