#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

class String

  CLS="\033[0;0f\033\[2J".freeze

  @color_codes = {
    :black   => 0, :light_black    => 60,
    :red     => 1, :light_red      => 61,
    :green   => 2, :light_green    => 62,
    :yellow  => 3, :light_yellow   => 63,
    :blue    => 4, :light_blue     => 64,
    :magenta => 5, :light_magenta  => 65,
    :cyan    => 6, :light_cyan     => 66,
    :white   => 7, :light_white    => 67,
    :default => 9
  }
  @color_codes.default=9
  @color_modes = {
    :default   => 0, # Turn off all attributes
    :bold      => 1, # Set bold mode
    :italic    => 3, # Set italic mode
    :underline => 4, # Set underline mode
    :blink     => 5, # Set blink mode
    :swap      => 7, # Exchange foreground and background colors
    :hide      => 8  # Hide text (foreground color would be the same as background)
  }
  @color_modes.default=0
  @syms = [:fg, :bg, :mode]

  class << self
    attr_reader :color_codes, :color_modes, :syms
    def create_methods
      color_codes.keys.each do |cc|
        next if cc == :default
        define_method cc do colorize(:fg=>cc) end
        define_method "on_#{cc}" do colorize(:bg=>cc) end
      end
      color_modes.keys.each do |cc|
        next if cc == :default
        define_method cc do colorize(:mode=>cc) end
      end

    end
  end
  create_methods

  START="\033[".freeze
  RESET="\033[0m".freeze
  START_RE=/^\033\[([0-9;]+)m/
  RESET_RE=/(?<!^)\033\[0m(?!$)/

  def colorize h
    code = h.inject([]) { |a,(k,v)| a<<resolve(k,v) if self.class.syms.include? k; a }.join(';')
    return code if code.empty?
    s = (
      if self =~ START_RE # merge with existing escape sequence
        prev = /(?<!^)\033\[#{$1}m(?!$)/
        code = START + $1 + ';' + code + 'm'
        self.sub(START_RE, code)
      else
        prev = RESET_RE
        code = START + code + 'm'
        code + self
      end
    )
    s.gsub!(prev, code)
    s+= RESET unless s[-4..] == RESET
    s
  end

  private

  def resolve k, v
    return self.class.color_codes[v] + 30 if k == :fg
    return self.class.color_codes[v] + 40 if k == :bg
    return self.class.color_modes[v] if k == :mode
  end

end

if $PROGRAM_NAME == __FILE__
  puts "RED >> #{"blue".colorize(:fg=>:blue,:bg=>nil)} #{"green".colorize(:fg=>nil).on_green} << DER".white.on_red.underline
end
