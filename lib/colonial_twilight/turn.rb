#! /usr/bin/env ruby
# frozen_string_literal: true

module ColonialTwilight
  OPERATIONS = {
    pass: 'Pass',
    rally: 'Rally',
    march: 'March',
    attack: 'Attack',
    terror: 'Terror'
  }.freeze

  SPECIAL_ACTIVITIES = {
    extort: 'Extort',
    subvert: 'Subvert',
    ambush: 'Ambush',
    oas: 'OAS'
  }.freeze

  class Action
    attr_reader :type, :space, :cost, :steps, :to_agitate_in
    attr_accessor :resources

    def initialize(type, space, cost, to_agitate_in: nil)
      @type = type
      @space = space
      @cost = cost
      @steps = []
      @resources = 0
      @to_agitate_in = to_agitate_in
    end

    def sanitize!
      map = { src_control: :src, dst_control: :dst }
      control = _collect_indexes(map)
      control.each do |k, v|
        v.pop
        v.each do |i|
          step = steps[i]
          step.delete(step[:src] == k ? :src_control : :dst_control)
        end
      end
    end

    def _collect_indexes(map)
      hash = {}
      steps.each_with_index do |step, i|
        map.each do |k, v|
          if step.key?(k)
            hash[step[v]] ||= []
            hash[step[v]] << i
          end
        end
      end
      hash
    end

    def name
      return 'Agitate' if @type == :agitate

      operation? ? OPERATIONS[@type] : SPECIAL_ACTIVITIES[@type]
    end

    def operation?
      OPERATIONS.keys.include? @type
    end

    def special_activity?
      SPECIAL_ACTIVITIES.keys.include? @type
    end

    def transfer_steps(steps)
      steps.each do |k, v|
        transfer_from(k, :fln_underground, v)
      end
      self
    end

    def pass
      @steps << { kind: :pass }
      self
    end

    def activate(num = 1)
      @steps << { kind: :activate, src: @space, num: num } if num.positive?
      self
    end

    def transfer_to(dst, what, num = 1, flip: false)
      @steps << { kind: :transfer, src: @space, dst: dst, what: what, num: num, flip: flip } if num.positive?
      self
    end

    def transfer_from(src, what, num = 1, flip: false)
      @steps << { kind: :transfer, src: src, dst: @space, what: what, num: num, flip: flip } if num.positive?
      self
    end

    def shift(num)
      @steps << { kind: :shift, dst: @space, num: num } unless num.zero?
      self
    end

    def extort
      @steps << { kind: :extort, src: @space, what: :fln_underground, flip: true }
      self
    end

    def terror
      @steps << { kind: :set, src: @space, what: :terror, terror: 1 }
      @steps << { kind: :set, src: @space, what: :alignment, alignment: :neutral }
      self
    end

    def agitate(terror, oppose)
      @steps << { kind: :agitate, src: @space, terror: terror, shift: oppose }
      self
    end

    def inspect
      "action #{@type} in '#{@space}'  cost: #{@cost} #{_to_agitate} : #{_steps}"
    end

    def _to_agitate
      @to_agitate_in.nil? ? '' : " - to agitate in #{@to_agitate_in}"
    end

    def _steps
      @steps.inject('') { |r, s| r + "\n    #{s.inspect}" }
    end
  end

  class Turn
    attr_reader :actions, :operation, :special_activity

    def initialize
      reset(false)
    end

    def reset(limited_op_only)
      @operation = nil
      @special_activity = nil
      @actions = []
      @limited_op_only = limited_op_only
    end

    def operation_done?
      !@operation.nil?
    end

    def special_activity_done?
      !@special_activity.nil?
    end

    def may_special_activity?(special_activity)
      @special_activity.nil? || @special_activity == special_activity
    end

    def operation_spaces
      @actions.select(&:operation?).size
    end
    alias selected_spaces operation_spaces

    def special_activity_spaces
      @actions.select(&:special_activity?).size
    end

    def operation_selected?(space)
      !@actions.select(&:operation?).find { |a| a.space == space }.nil?
    end

    def special_activity_selected?(space)
      !@actions.select(&:special_activity?).find { |a| a.space == space }.nil?
    end

    def cost
      @actions.inject(0) { |s, a| s + a.cost }
    end

    def operation_cost
      @actions.select(&:operation?).inject(0) { |s, a| s + a.cost }
    end

    def special_activity_cost
      @actions.select(&:special_activity?).inject(0) { |s, a| s + a.cost }
    end

    def pass(cost)
      operation_in(:pass, nil, -cost).pass
    end

    def agitate_in(space, terror, oppose)
      raise "illegal Agitate in #{@operation}" if @operation != :rally
      raise "not already selected : #{space.name}" unless operation_selected?(space)

      add Action.new(:agitate, space, terror + oppose).agitate(terror, oppose)
    end

    def operation_in(operation, space, cost, to_agitate_in: nil)
      raise "unknown operation : #{operation}" unless OPERATIONS.keys.include? operation

      unless @operation.nil?
        raise "illegal #{operation} in #{@operation}" if @operation != operation
        raise "illegal #{operation} in limited operation #{@operation}" if @limited_op_only
      end
      raise "already selected : #{space.name}" if operation_selected?(space)

      @operation = operation
      add Action.new(operation, space, cost, to_agitate_in: to_agitate_in)
    end

    def special_activity_in(special_activity, space, cost, to_agitate_in: nil)
      raise "unknown special activity : #{special_activity}" unless SPECIAL_ACTIVITIES.keys.include? special_activity
      raise "illegal #{special_activity} in #{@special_activity}" if !@special_activity.nil? && @special_activity != special_activity
      raise "illegal #{special_activity} in limited operation #{@operation}" if @limited_op_only
      raise "already selected : #{space.name}" if special_activity_selected?(space)

      @special_activity = special_activity
      @operation = :attack if special_activity == :ambush
      add Action.new(special_activity, space, cost, to_agitate_in: to_agitate_in)
    end

    def add(action)
      @actions << action
      action
    end

    def inspect
      "Operation : #{@operation} - in #{selected_spaces} spaces => #{operation_cost} Resources\
      \nSpecial Activity : #{@special_activity} - in #{special_activity_spaces}\
      spaces => #{special_activity_cost} Resources\
      \nactions : #{_actions_to_s}"
    end

    def _actions_to_s
      @actions.inject('') { |s, a| s + "\n  - #{a.inspect}" }
    end
  end
end
