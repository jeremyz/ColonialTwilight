#! /usr/bin/env ruby
# frozen_string_literal: true

# this adds ascii colorization to String class
class String
  RESET = "\033[0m"
  CLEAR_LINE = "\33[2K\r"
  CLS = "\033[0;0f\033\[2J"

  @color_codes = {
    black: 0,   light_black: 60,
    red: 1,     light_red: 61,
    green: 2,   light_green: 62,
    yellow: 3,  light_yellow: 63,
    blue: 4,    light_blue: 64,
    magenta: 5, light_magenta: 65,
    cyan: 6,    light_cyan: 66,
    white: 7,   light_white: 67,
    default: 9
  }
  @color_codes.default = 9
  @color_modes = {
    default: 0, # Turn off all attributes
    bold: 1,
    dim: 2,
    italic: 3,
    underline: 4,
    blink: 5,
    swap: 7,    # Exchange foreground and background colors
    hide: 8     # Hide text (foreground color would be the same as background)
  }
  @color_modes.default = 0
  @syms = %i[fg bg mode]

  class << self
    attr_reader :color_codes, :color_modes, :syms

    def create_methods
      color_codes.each_key do |cc|
        next if cc == :default

        define_method(cc) { colorize(fg: cc) }
        define_method("on_#{cc}") { colorize(bg: cc) }
      end
      color_modes.each_key do |cc|
        next if cc == :default

        define_method(cc) { colorize(mode: cc) }
      end
    end
  end
  create_methods

  def colorize(opts)
    # code = compile_code(opts)
    code = opts.each_with_object([]) { |(k, v), a| a << resolve(k, v) if self.class.syms.include? k }.join(';')
    return self if code.empty?

    apply_code(code)
  end

  private

  START_CODE = /^\033\[([0-9;]+)m/.freeze
  # negative lookbehind : (?<! ) + ^ => is not at the start of the line
  # negative lookahead : (?! ) + $ => is not at the end of the line
  MIDDLE_RESET = /(?<!^)\033\[0m(?!$)/.freeze

  def apply_code(code)
    # prefix with ascii code
    # replace all not ending reset with ascii code
    if self =~ START_CODE
      prev_start_code = ::Regexp.last_match(1)
      # puts "merge : #{code} to #{prev_start_code}"
      # merge in front to preserve previous formating
      mcode = "\033[#{code};#{prev_start_code}m"
      # replace starting code and middle prev code with merged one
      # replace middle reset code with new code
      # the latter does not work on multiple pass like ' '.red.on_blue
      # reset middle code will become red, nothin will be done with blue
      s = sub(START_CODE, mcode)
          .gsub(MIDDLE_RESET, "\033[#{code}m")
          .gsub(/(?<!^)\033\[#{prev_start_code}m(?!$)/, mcode)
    else
      # puts "add : #{code}"
      code = "\033[#{code}m"
      s = (code + self).gsub(MIDDLE_RESET, code)
    end
    # add terminal reset if needed
    (s[-4..] == RESET ? s : s + RESET)
  end

  def resolve(key, var)
    return self.class.color_codes[var] + 30 if key == :fg
    return self.class.color_codes[var] + 40 if key == :bg
    return self.class.color_modes[var] if key == :mode
  end
end

if $PROGRAM_NAME == __FILE__
  a = 'blue'.colorize(fg: :blue, bg: nil)
  b = 'green'.colorize(fg: nil).on_green
  puts "RED >> #{a} #{b} << DER".white.on_red.underline
end
