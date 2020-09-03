#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

module ColonialTwilight

  class Player

    attr_reader :faction

    def initialize game, faction
      @game = game
      @board = game.board
      @faction = faction
      @debug = game.options.debug_bot
      @possible_actions = nil
    end

    def _init
      @card = @game.current_card
      @operation = nil
      @operation_count = 0
      @special_activity = nil
      @special_activity_count = 0

      @selected_spaces = []
      @expended_resources = 0
    end

    def conducted_action
      a = nil
      if not @card.nil?
        raise "Operation #{@operation} conducted with event" if not @operation.nil?
        raise "Special Activity #{@special_activity} conducted with event" if not @special_activity.nil?
        a = :event
      elsif not @special_activity.nil?
        a = :ope_special
      else
        if @operation_count == 0
          a = :pass
        elsif @operation_count == 1
          a = :ope_limited
        else
          a = :ope_only
        end
      end
      raise "#{a} has been conducted but is not allowed" if not @possible_actions.include? a
      puts "Conducted action is : #{a}" if @debug
      a
    end

    private

    def first_eligible?
      @game.actions.size == 0
      # @possible_actions.length == 5
    end

    def may_play_event?
      not @card.nil? and @possible_actions.include? :event
    end

    def limited_ope_only?
      (@possible_actions.size == 2 and @possible_actions.include? :ope_limited)
    end

    def limited_ope_done?
      limited_ope_only? and @operation_count == 1
    end

    def may_conduct_special_activity? sp
      r = @possible_actions.include? :ope_special
      r &= (sp == @special_activity) if not @special_activity.nil?
      r
    end

    def operation_done ope
      raise "try to conduct ope #{ope} over #{@operation}" if not (@operation.nil? or @operation == ope)
      raise "cannot conduct another" if @operation_count > 0 and limited_ope_only?
      @card = nil
      @operation = ope
      @operation_count += 1
    end

    def special_activity_done sp
      raise "try to conduct special activity #{sp} over #{@special_activity}" if not (@special_activity.nil? or @special_activity == sp)
      raise "cannot conduct a special activity" if not may_conduct_special_activity? sp
      @card = nil
      @special_activity = sp
      @special_activity_count += 1
    end

    def debug_selected_spaces
      puts "\tselected spaces :: " + @selected_spaces.collect(){|s| s.is_a?(Symbol) ? s.to_s : s.name}.join(' :: ') if @debug
    end

  end

end
