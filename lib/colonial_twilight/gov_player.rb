#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

module ColonialTwilight

  class GOVPlayer < Player

    def play possible_actions
      @possible_actions = possible_actions
      _init
      _start
    end

    private

    def _start
      puts "FIXME"
      exit 1
    end

  end

end
