#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

require 'colonial_twilight'
require 'colonial_twilight/colorized_string'
require 'colonial_twilight/game'

module ColonialTwilight

  class Sector
    def cli
      name.magenta
    end
    def towhat?; true end
  end

  class Box
    def cli
      Cli::BOXES[name].cyan
    end
    def towhat?; false end
  end

  class Cli

    FRANCE_TRACK=[' A ',' B ',' C ',' D ',' E ',' F '].map {|e| e.white.on_blue}.freeze
    TRACK = {
      :support_commitment => ' Support & Commitment '.white.on_blue,
      :opposition_bases => ' FLN bases & Opposition '.black.on_green
    }
    FACTION = {
      :FLN => ' FLN '.black.on_green,
      :GOV => ' Government '.white.on_blue
    }.freeze
    CONTROL = {
      :FLN => ' FLN '.black.on_green,
      :GOV => ' Government '.white.on_blue,
      :uncontrolled => ' Uncontrolled '.black.on_light_white
    }.freeze
    ALIGNMENT = {
      :oppose => ' Oppose '.black.on_green,
      :support => ' Support '.white.on_blue,
      :neutral => ' Neutral '.black.on_light_white
    }.freeze
    BOXES = {
      :available => 'Available'.cyan,
      :out_of_play => 'Out Of Play'.cyan,
      :casualties => 'Casualties'.cyan,
      :france_track => 'France Track'.white.on_blue,
      :border_track => 'Border Track'.yellow.on_black,
    }.freeze
    FORCES = {
      :fln_active=>'Active Guerrillas'.red.on_black,
      :fln_underground=>'Underground Guerrillas'.green.on_black,
      :fln_base=>'FLN Base'.white.on_black,
      :french_troops=>'French Troops'.on_blue,
      :french_police=>'French Police'.black.on_light_blue,
      :gov_base=>'Government Base'.on_blue,
      :algerian_troops=>'Algerian Troops'.black.on_green,
      :algerian_police=>'Algerian Police'.black.on_light_green
    }.freeze

    def initialize options
      @options = options
      @game = ColonialTwilight::Game.new options
    end

    def start
      logo
      ret = []
      ret << chose('Choose a scenario', @game.scenarios) { |s| a = s.split(':'); a[0] = a[0].yellow; a.join(':') }
      exit(0) if ret[-1] < 0
      ret << chose('Choose a ruleset', @game.rules) { |s| a = s.split('-'); a[0] = a[0].yellow; a.join('-') }
      exit(0) if ret[-1] < 0
      @game.start self, *ret
      @game.play
    end

    def logo
      clear_screen
      puts ('  ____      _             _       _   _____          _ _ _       _     _    '+
            "\n"' / ___|___ | | ___  _ __ (_) __ _| | |_   _|_      _(_) (_) __ _| |__ | |_  ' +
            "\n"'| |   / _ \| |/ _ \| \'_ \| |/ _` | |   | | \ \ /\ / / | | |/ _` | \'_ \| __| ' +
            "\n"'| |__| (_) | | (_) | | | | | (_| | |   | |  \ V  V /| | | | (_| | | | | |_  ' +
            "\n"' \____\___/|_|\___/|_| |_|_|\__,_|_|   |_|   \_/\_/ |_|_|_|\__, |_| |_|\__| ' +
            "\n"'                                                           |___/            ').white.bold.on_light_green
      puts "version : #{ColonialTwilight::VERSION.red}".black.on_white
    end

    def clear_screen
      puts String::CLS
    end

    def turn_start turn, first, second
      clear_screen if @options.clearscreen
      puts
      puts ("=" * 80).white.bold.on_light_green
      puts " Turn : #{turn.to_s.red} ".black.on_white + "\t 1st Eligible : ".black.on_white + FACTION[first.faction]
      puts "\t\t 2nd Eligible : ".black.on_white + FACTION[second.faction]
    end

    def pull_card max
      puts
      printf "Enter the current #{'card number'.yellow} : "
      while true
        s = gets.chomp
        if s.to_i.to_s == s.to_s
          ret = s.to_i
          return ret if ret < max
        end
        puts "\t\t\t\t'#{s}' is not valid, must be one of [1..#{max}]"
        printf "\t$ "
      end
    end

    def show_card card
      puts
      puts "Current event card : ##{card.num.to_s.yellow} #{card.title.red}"
    end

    def player p, first
      puts
      clear_screen if @options.clearscreen
      puts
      puts " #{FACTION[p.faction]} is #{first ? '1st Eligible' : '2nd Eligible'}".black.on_white
    end

    def adjust_track ar
      puts
      puts "\tadjust #{TRACK[:support_commitment]} from #{ar[0].to_s.cyan} to #{ar[2].to_s.red}" if ar[0] != ar[2]
      puts "\tadjust #{TRACK[:opposition_bases]} from #{ar[1].to_s.cyan} to #{ar[3].to_s.red}" if ar[1] != ar[3]
    end

    def show_player_action player, h
      selected = h[:selected]
      faction = FACTION[player.faction]
      puts
      show_action(faction, selected, h) if h.has_key? :action
      # show_activity(faction, selected, h) if h.has_key? :activity
      show_transfers(selected, h[:transfers]) if h.has_key? :transfers
      show_markers(selected, h[:markers]) if h.has_key? :markers
      show_controls(selected, h[:controls]) if h.has_key? :controls
      case selected
      when :france_track
        puts "\t   => shift #{1.to_s.cyan} space onto #{FRANCE_TRACK[h[:france_track]]}"
      when :border_track
        puts "\t   => shift #{1.to_s.cyan} space onto #{h[:border_track].to_s.yellow.on_black}"
      end
      print "\u21b5  " # carriage return
      gets
      print "\033[1A\033[K\u2713\n\n" # up, erase line, check
    end

    # def show_control selected, control
    #     s = "\t   => shift #{'control'.cyan} to #{CONTROL[control]}"
    #     s += " in #{selected.magenta}" if @options.verbose
    #     puts s
    # end

    def show_controls selected, controls
      controls.each do |k,v|
        puts "\t   => shift #{'control'.cyan} to #{CONTROL[v[1]]} in #{k.cli}" if k != selected
      end
      if controls.has_key? selected
        s = "\t   => shift #{'control'.cyan} to #{CONTROL[controls[selected][1]]}"
        s += " in #{selected.cli}" if @options.verbose
        puts s
      end
    end

    def show_action faction, selected, h
      action = h[:action]
      rcs = h[:resources]
      incr = (rcs[:cost] <=> 0)
      v = rcs[:cost].abs.to_s.cyan
      if action == :pass
        puts "\t#{'PASS'.red} increase #{'resources'.yellow} by #{v} to #{rcs[:value].to_s.red}"
      else
        action = action.to_s.capitalize
        sym = selected.is_a?(Symbol)  # FIXME Symbol => France track or Border track
        where = sym ? "on #{BOXES[selected]}" : "in #{selected.cli}"
        cost = (incr == 0 ? nil : "#{incr < 0 ? 'increase' : 'decrease'} #{'resources'.yellow} by #{v} to #{rcs[:value].to_s.red}")
        if @options.verbose
          puts "\t#{faction} executes a #{action.yellow} Operation #{where}"
          puts "\t#{cost}" unless cost.nil?
          puts "\tin #{selected.cli} :" unless sym
        else
          s = "\t#{action.black.on_white} #{where} "
          s += cost unless cost.nil?
          puts s
        end
      end
    end

    def show_transfers selected, transfers
      transfers.each do |tr|
        n = tr[:n].to_s.cyan
        from, to = tr[:from], tr[:to]
        what, towhat = tr[:what], tr[:towhat]
        if from == to
          s = "\t   => flip #{n} #{FORCES[what]} to #{FORCES[towhat]}"
          s += " in #{selected.cyan}" if @options.verbose
          puts s
        else
          s = "\t   => transfer #{n} #{FORCES[what]}"
          s += " from #{from.cli}" if @options.verbose or from != selected
          s += " to #{to.cli}" if @options.verbose or to != selected
          s += " as #{FORCES[towhat]}" if @options.verbose or (what != towhat and to.towhat?)
          # puts "\t   => shift #{'control'.cyan} to #{CONTROL[controls[from]]} in #{from.cli}" if from != selected and controls.has_key?(from)
          # puts "\t   => shift #{'control'.cyan} to #{CONTROL[controls[to]]} in #{to.cli}" if to != selected and controls.has_key?(to)
          puts s
        end
      end
    end

    def show_markers selected, markers
      markers.each do |mk|
        what, n, towards, from, to = mk
        case what
        when :terror
          act = (n > 0 ? 'add' : 'remove').red
          s = "\t   => #{act} #{n.to_s.cyan} #{'Terror'.yellow} markers"
          s += " in #{selected.cli} from #{from.to_s.cyan} to #{to.to_s.red}" if @options.verbose
          puts s
        when :alignment
          if @options.verbose
            puts "\t   => shift #{selected.cli} #{n.to_s.cyan} times towards #{ALIGNMENT[towards]} from #{ALIGNMENT[from]} to #{ALIGNMENT[to]}"
          else
            puts "\t   => shift #{'Alignment'.yellow} onto #{ALIGNMENT[to]}"
          end
        end
      end
    end

    def continue? bot
      l = bot ? ["FLN :\t\tlet the FLN bot play", "Pivotal Event:\tplay a Pivotal Event"] : ["Play:\t\tplay your turn"]
      ret = chose('Next action', l, true) { |s| a = s.split(':'); a[0] = a[0].yellow; a.join(':') }
      exit(0) if ret < 0
    end

    def chose prompt, list, quit=false
      puts
      puts " => #{prompt.yellow}:"
      puts ('-'*(prompt.size + 5)).white.bold
      list.each_with_index do |el, i|
        puts "\t#{(i+1).to_s.bold}) : #{block_given? ? yield(el): el}"
      end
      puts "\tq) : Quit" if quit

      printf "\t$ "
      ret = -1
      while true
        s = gets.chomp
        return -1 if s == 'q'
        if s.to_i.to_s == s.to_s
          ret = s.to_i
          return ret - 1 if ret >= 1 and ret <= list.length
        end
        puts "\t\t\t\t'#{s}' is not valid, must be one of [1..#{list.length}]"
        printf "\t$ "
      end
    end

    YES=['y','yes']
    NO=['n','no']
    def ask prompt, default=nil
      puts
      c = (default.nil? ? 'y/n' : (default ? 'Y/n' : 'y/N'))
      printf " => #{prompt.yellow} (#{c}) ? "
      while true
        ret = gets.chomp.downcase
        return true if YES.include? ret
        return false if NO.include? ret
        return default if not default.nil?
        puts "\t\t\t\t'#{ret}' is not valid, (y/n) ?"
        printf "\t$ "
      end
    end

  end

end

if $PROGRAM_NAME == __FILE__
  class O
    def clearscreen; false end
  end
  class P
    def initialize f; @faction = f end
    def faction; @faction end
  end
  io = ColonialTwilight::Cli.new O.new
  io.logo
  puts
  l = ['Short: 1960-1962: The End Game','Medium: 1957-1962: Midgame Development','Full: 1955-1962: Algerie Francaise!']
  ret = io.chose('Choose a scenario', l) { |s| a = s.split(':'); a[0] = a[0].yellow; a.join(':') }
  puts l[ret]
  ret = io.ask 'Are you sure'
  puts ret
  ret = io.ask 'Are you sure', true
  puts ret
  ret = io.ask 'Are you sure', false
  puts ret
  puts
  io.turn_start 666, P.new(:FLN), P.new(:GOV)
  ColonialTwilight::Cli::FACTION.each do |k,f|
    puts " #{k} => #{f}"
  end
  ColonialTwilight::Cli::CONTROL.each do |k,f|
    puts " #{k} => #{f}"
  end
  ColonialTwilight::Cli::ALIGNMENT.each do |k,f|
    puts " #{k} => #{f}"
  end
  ColonialTwilight::Cli::BOXES.each do |k,f|
    puts " #{k} => #{f}"
  end
  ColonialTwilight::Cli::FORCES.each do |k,f|
    puts " #{k} => #{f}"
  end
end
