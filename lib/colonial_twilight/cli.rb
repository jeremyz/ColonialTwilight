#! /usr/bin/env ruby
# frozen_string_literal: true

require 'io/console'
require_relative 'colorized_string'

class Integer
  def from
    to_s.cyan
  end

  def to
    to_s.red
  end
end

class Symbol
  def from
    to_s.cyan
  end

  def to
    to_s.red
  end
end

module ColonialTwilight
  module CliDefinitions
    FRANCE_TRACK = [' A ', ' B ', ' C ', ' D ', ' E ', ' F '].map { |e| e.white.on_blue }.freeze

    TRACK = {
      gov_score: ' Support & Commitment '.blue.on_black,
      gov_resources: ' Resources '.blue.on_black,
      fln_score: ' FLN bases & Opposition '.green.on_black,
      fln_resources: ' Resources '.green.on_black
    }.freeze

    FACTION = {
      FLN: ' FLN '.black.on_green,
      GOV: ' Government '.white.on_blue
    }.freeze

    CONTROL = {
      FLN: ' FLN '.black.on_green,
      GOV: ' Government '.white.on_blue,
      uncontrolled: ' Uncontrolled '.black.on_light_white
    }.freeze

    ALIGNMENT = {
      oppose: ' Oppose '.black.on_green,
      support: ' Support '.white.on_blue,
      neutral: ' Neutral '.black.on_light_white
    }.freeze

    BOXES = {
      available: 'Available'.cyan,
      out_of_play: 'Out Of Play'.cyan,
      casualties: 'Casualties'.cyan,
      france_track: 'France Track'.white.on_blue,
      border_track: 'Border Track'.yellow.on_black
    }.freeze

    FORCES = {
      fln_active: 'Active Guerrillas'.red.on_black,
      fln_underground: 'Underground Guerrillas'.green.on_black,
      fln_base: 'FLN Base'.white.on_black,
      french_troops: 'French Troops'.on_blue,
      french_police: 'French Police'.black.on_light_blue,
      gov_base: 'Government Base'.on_blue,
      algerian_troops: 'Algerian Troops'.black.on_green,
      algerian_police: 'Algerian Police'.black.on_light_green
    }.freeze

    MARKERS = {
      terror: 'Terror Marker'.yellow,
      control: 'Control'.yellow,
      alignment: 'Alignment'.yellow
    }.freeze
  end

  module CliUtils
    def clear_screen
      puts String::CLS
    end

    def wait_enter
      print "\u21b5  " # carriage return
      gets
      print "\033[1A\033[K\u2713\n" # up, erase line, check
    end

    def logo
      puts '  ____      _             _       _   _____          _ _ _       _     _    '.white.bold.on_light_green
      puts ' / ___|___ | | ___  _ __ (_) __ _| | |_   _|_      _(_) (_) __ _| |__ | |_  '.white.bold.on_light_green
      puts '| |   / _ \| |/ _ \| \_ `| |/ _` | |   | | \ \ /\ / / | | |/ _` | \_ `| __| '.white.bold.on_light_green
      puts '| |__| (_) | | (_) | | | | | (_| | |   | |  \ V  V /| | | | (_| | | | | |_  '.white.bold.on_light_green
      puts ' \____\___/|_|\___/|_| |_|_|\__,_|_|   |_|   \_/\_/ |_|_|_|\__, |_| |_|\__| '.white.bold.on_light_green
      puts '                                                           |___/            '.white.bold.on_light_green
      puts "version : #{ColonialTwilight::VERSION.red}".black.on_white
    end

    def split_colon(txt)
      a = txt.split(':')
      a[0] = a[0].yellow
      a.join(':')
    end

    def chose(prompt, list, quit: true)
      puts "\n => #{prompt.yellow}:"
      puts ('-' * (prompt.size + 5)).white.bold
      list.each_with_index do |el, i|
        puts "\t#{(i + 1).to_s.bold}) : #{block_given? ? yield(el) : el}"
      end
      puts "\tq) : Quit" if quit
      print "\t$ "
      read_int_or_quit(list.length)
    end

    def read_int_or_quit(max)
      loop do
        s = gets.chomp.strip
        exit(0) if s == 'q'
        if s =~ /^([0-9]+)$/
          i = ::Regexp.last_match(1).to_i
          return i - 1 if i.positive? && (max.nil? || i <= max)
        end
        puts "\t  #{s} is not valid#{max.nil? ? '' : ", must be one of [1..#{max}]"} or 'q'"
        print "\t$ "
      end
    end

    def select_from(list)
      l = []
      chrs = []
      show_list(chrs, l)
      loop do
        chrs = add_char(chrs, $stdin.getch)
        if chrs[-1].nil?
          chrs = chrs[..-2]
          return l[0] if !l.empty? && !chrs.empty?
        end
        l = strict_match(list, chrs.join)
        l = chars_match(list, chrs) if l.empty?
        show_list(chrs, l)
      end
    end

    def show_list(chrs, list)
      s = (
      if chrs.size < 2
        "#{(chrs.empty? ? '?' : chrs.join).white.bold} : ..."
      else
        "#{chrs.join.white.bold} : #{ansi_list(chrs, list)}"
      end)
      print "#{String::CLEAR_LINE}#{s}"
    end

    def ansi_list(chrs, list)
      list.join(' * ').chars.map { |c| chrs.include?(c.downcase) ? c.white.bold : c }.join
    end

    def add_char(chrs, chr)
      case chr.ord
      when 13
        chrs << nil
      when 8
        chrs[..-2]
      else
        chrs << chr.downcase
      end
    end

    def strict_match(list, chars)
      list.select { |s| s.downcase =~ /#{chars}/ }
    end

    def chars_match(list, chars)
      list.select { |s| chars.inject(true) { |v, c| v & s.downcase.include?(c) } }
    end

    def yes_no_string(default)
      case default
      when nil   then 'y/n'
      when true  then 'Y/n'
      when false then 'y/N'
      end
    end

    YES = %w[y yes].freeze
    NO = %w[n no].freeze
    def ask(prompt, default = nil)
      c = yes_no_string(default)
      puts
      print " => #{prompt.yellow} (#{c}) ? "
      loop do
        ret = gets.chomp.strip.downcase
        return true if YES.include? ret
        return false if NO.include? ret
        return default if ret.empty? && !default.nil?

        puts "\t\t\t\t'#{ret}' is not valid, (#{c}) ?"
        print "\t$ "
      end
    end
  end

  class Cli
    include CliDefinitions
    include CliUtils

    def initialize(options)
      @options = options
    end

    def welcome
      clear_screen if @options.clearscreen
      logo
    end

    def chose_scenario(scenarios)
      chose('Choose a scenaroo', scenarios) { |_k, v| split_colon(v) }
    end

    def chose_rules(rules)
      chose('Choose a ruleset', rules) { |_k, v| split_colon(v) }
    end

    def turn_start(turn, first, second)
      clear_screen if @options.clearscreen
      puts
      puts ('=' * 80).white.bold.on_light_green
      puts " Turn : #{turn.to} ".black.on_white << "\t 1st Eligible : ".black.on_white << FACTION[first.faction]
      puts "\t\t 2nd Eligible : ".black.on_white + FACTION[second.faction]
    end

    def continue?(player)
      if player.instance_of?(FLNBot)
        l = ["#{'FLN'.yellow} :\t\tlet the FLN bot play", "#{'Pivotal Event'.yellow} :\tplay a Pivotal Event"]
      elsif player.instance_of?(GOVPlayer)
        l = ["#{'Play'.yellow}:\t\tplay your turn"]
      else
        puts ''
        exit(1)
      end
      chose('Next action', l)
    end

    def d6
      # FIXME: add options to roll dice -> read_int(1-6)
      rand(7)
    end

    def pull_card(max)
      print "\nEnter the current #{'card number'.yellow} : "
      read_int_or_quit(max) + 1
    end

    def show_card(card)
      puts "\nCurrent card : ##{card.num.to_s.yellow} #{card.title.red} #{show_capability card} #{show_momentum card}"
    end

    def show_capability(card)
      s = ''
      s += ' FLN capability'.white.on_green if card.fln_capability?
      s += ' GOV capability'.white.on_blue if card.gov_capability?
      s += 'DUAL capability'.white if card.dual_capability?
      s
    end

    def show_momentum(card)
      s = ''
      s += ' FLN momentum'.white.on_green if card.fln_momentum?
      s += ' GOV momentum'.white.on_blue if card.gov_momentum?
      s += 'DUAL momentum'.white if card.dual_momentum?
      s
    end

    def show_player(player, first)
      clear_screen if @options.clearscreen
      st = first ? '1st Eligible' : '2nd Eligible'
      puts "\n\n #{FACTION[player.faction]} #{st}".black.on_white + " - #{resources(player)} - #{score(player)}\n\n"
    end

    def show_action(action)
      show_steps action
      show_cost action
      wait_enter
    end

    def select_by_name(list)
      puts
      r = nil
      loop do
        r = select_from(list)
        break if ask "\n => #{r}", true
      end
      r
    end

    private

    def resources(player)
      resources = "#{player.faction.to_s.downcase}_resources".to_sym
      "#{player.resources.to_s.yellow} #{TRACK[resources]}"
    end

    def score(player)
      score = "#{player.faction.to_s.downcase}_score".to_sym
      "#{player.score.to_s.yellow} #{TRACK[score]}"
    end

    # ACTIONS

    def show_cost(action)
      return if action.cost.zero?

      v = action.cost.abs
      sign = action.cost.negative? ? 'increase' : 'decrease'
      puts "\t=> #{sign} #{'resources'.yellow} by #{v.from} to #{action.resources.to}"
    end

    def show_steps(action)
      return show_pass(action) if action.type == :pass

      puts "  #{action.name.yellow} in #{to_cli(action.space)}#{to_agitate(action)}"
      action.steps.each do |step|
        s = case step[:kind]
            when :transfer then show_transfer(step, action.space)
            when :shift then show_shift(step)
            when :set then show_set(step)
            when :extort then show_extort(step)
            when :agitate then show_agitate(step)
            end
        # show_action(faction, selected, action) if action.key? :action
        # # show_activity(faction, selected, action) if action.key? :activity
        # show_markers(selected, action[:markers]) if action.key? :markers
        # show_controls(selected, action[:controls]) if action.key? :controls
        # if selected == :france_track
        #   puts "\t   => shift #{1.to_s.cyan} space onto #{FRANCE_TRACK[action[:france_track]]}"
        # elsif selected == :border_track
        #   puts "\t   => shift #{1.to_s.cyan} space onto #{action[:border_track].to_s.yellow.on_black}"
        # end
        puts s unless s.nil?
      end
    end

    def to_agitate(action)
      action.to_agitate_in.nil? ? '' : " to #{'Agitate'.yellow} in #{to_cli(action.to_agitate_in)}"
    end

    def show_pass(action)
      puts "  #{action.name.yellow}"
    end

    def show_transfer(step, selected)
      src = to_cli(step[:src])
      dst = to_cli(step[:dst])
      flip = !step[:flip]
      s = "\t=> transfer #{step[:num].to} #{FORCES[step[:what]]}"
      s += " from #{src}" if @options.verbose || step[:src] != selected
      s += " to #{dst}" if @options.verbose || step[:dst] != selected
      s += " as #{FORCES[step[:flip]]}" unless flip
      # FIXME: only if last step, what does it mean ??
      show_control_shift(s, step, src, dst)
    end

    def show_shift(step)
      n = step[:num].from
      case step[:dst]
      when :france_track then "\t=> shift #{n} space onto #{FRANCE_TRACK[step[:track]]}"
      when :border_track then "\t=> shift #{n} space onto #{BOXES[:border_track]}"
      end
    end

    def show_set(step)
      return if (w = step[:what]).nil?

      t = (v = step[w]).instance_of?(Integer) ? v.to : ALIGNMENT[v]
      "\t=> set #{MARKERS[w]} to #{t}"
    end

    def show_extort(_step)
      # src = to_cli(step[:src])
      "\t=> flip 1 #{FORCES[:fln_underground]} to #{FORCES[:fln_active]}"
    end

    def show_agitate(step)
      s = (step[:terror].zero? ? '' : "\t=> remove #{step[:terror].from} #{MARKERS[:terror]} to #{step[:terror_level].to}")
      s += "\n" if !s.empty? && step[:shift].positive?
      s += "\t=> shift #{MARKERS[:alignment]} to #{ALIGNMENT[step[:alignment]]}" if step[:shift]
      s
    end

    # def show_cube_shift
    #   s += "\t   => flip #{n} #{FORCES[what]} to #{FORCES[towhat]}"
    #   s += " in #{selected.cyan}" if @options.verbose
    # end

    def show_control_shift(str, step, src, dst)
      str += "\n\t=> shift #{MARKERS[:control]} to #{CONTROL[step[:src_control]]} in #{src}" if step.key? :src_control
      str += "\n\t=> shift #{MARKERS[:control]} to #{CONTROL[step[:dst_control]]} in #{dst}" if step.key? :dst_control
      str
    end

    def to_cli(obj)
      obj.instance_of?(Symbol) ? BOXES[obj] : obj.name.magenta
    end
  end
end
