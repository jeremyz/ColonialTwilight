#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

require 'colonial_twilight'
require 'colonial_twilight/colorized_string'
require 'colonial_twilight/game'

module ColonialTwilight

  class Cli

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

    PS = { :FLN => 'FLN'.red, :GOV => 'Government'.red }

    def turn_start turn, first, second
      clear_screen if @options.clearscreen
      puts
      puts ("=" * 80).white.bold.on_light_green
      puts " Turn : #{turn.to_s.red} ".black.on_white + "\t First Eligible  : #{PS[first.faction]} ".black.on_white
      puts "\t\t Second Eligible : #{PS[second.faction]} ".black.on_white
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
      puts " #{PS[p.faction]} is #{first ? 'First Eligible' : 'Second Eligible'}".black.on_white
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
  io = ColonialTwilight::Cli.new
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
  io.turn_start(1, [:FLN, :GOV])
end
