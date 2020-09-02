#! /usr/bin/env ruby
# -*- coding: UTF-8 -*-

module ColonialTwilight

  # Country.independant

  class FLNBot < Player

    def play possible_actions
      @possible_actions = possible_actions
      _init
      _start
    end

    private

    def _start
      # resources = 0 && Ope Limited as only choice
      if @board.fln_resources == 0 and limited_ope_only?
        puts ' => PASS' if @debug
        h = get_action :pass, -1, :pass, false
        apply_action h
        return conducted_action
      end

      # GOV is first eligible && will be second eligible
      if not first_eligible? and @game.eligibility_swap?
        puts ' => TERROR 1' if @debug
        return terror
      end

      # exists no FLN base with (POP 1+ && 1- FLN undeground OR POP 0 && 0 FLN underground)
      if not @board.has(:sectors) {|s| s.fln_bases_1m? and ((not s.pop0? and s.fln_u_1l?) or (s.pop0? and s.fln_u_0?)) }
        puts ' => TERROR 2' if @debug
        return terror
      end

      return _march_or_rally
    end

    def _march_or_rally
      # rally would place base : see rally first 2 bullets
      if @board.available_fln_bases > 0 and @board.has {|s| may_add_fln_base?(s) and ((s.guerrillas >= 3 and (limited_ope_only? ? true : s.gov_cubes_0?)) or s.guerrillas >= 4) }
        puts ' => RALLY 1' if @debug
        return rally
      end

      # #FLN bases * 2 > #FLN at FLN bases + 1d6/2
      if (@board.count() {|s| s.fln_bases } * 2) > (@board.count() {|s| s.fln_bases_0? ? 0 : s.guerrillas } + rand(7)/2)
        puts ' => RALLY 2' if @debug
        return rally
      end

      puts ' => MARCH 1' if @debug
      return march
    end

    ##### TERROR OPERATION #####
    def terror
      # not POP 0 && 1+ FLN underground && (no FLN bases || 2+ FLN underground)
      spaces = @board.search(:sectors) {|s| not s.pop0? and s.fln_u_1m? and (s.fln_bases_0? or s.fln_u_2m?) }

      # play event if more profitable
      vpts = 0
      (@board.fln_resources + possible_extort).clamp(0, spaces.length).times {|n| vpts += spaces[n].pop }
      return event if spaces.empty? or (may_play_event? and vpts <= @card.fln_effectiveness)

      # to remove support, highest POP first
      sort_filter(spaces.select{|s| s.support? }, :pop).each do |selected|
        break if not may_continue?
        _terror selected
        spaces.delete selected
      end

      # if last campaign, neutral with no terror and pacifiable, highest POP first
      sort_filter(spaces.select{|s| s.neutral? and not s.has_terror? and pacifiable?(s) and not_selected s }, :pop).each do |selected|
        break if not may_continue?
        _terror selected
        spaces.delete selected
      end if last_campaign?

      subvert if may_conduct_special_activity? :subvert
      extort if may_conduct_special_activity? :extort

      return conducted_action
    end

    def _terror selected
      h = get_action :terror, 1, selected
      transfer h, 1, :fln_underground, selected, selected, :fln_active
      mks = []
      mks << [:terror, 1, nil, 0, 1] if not selected.terror?
      mks << [:alignment, 1, :support, :oppose, :neutral] if selected.oppose?
      mks << [:alignment, 1, :oppose, :support, :neutral] if selected.support?
      h[:markers] = mks
      apply_action h
    end

    ##### EVENT #####
    def event
      if may_play_event? and @card.fln_effective? and ((@card.fln_marked? or @card.capability?) or (rand(7) < 4 and @card.fln_playable?))
        raise "FIXME event not implemented yet"
        return conducted_action
      end
      return attack
    end

    ##### SUBVERT SPECIAL ACTIVITY #####
    def subvert
      puts ' => SUBVERT' if @debug
      puts ':: 1+ FLN underground && 1+ algerian cubes' if @debug
      spaces = @board.search(:sectors) {|s| s.fln_u_1m? and s.algerian_cubes >= 1 }

      # in up to 2 spaces, to remove last cube
      tmp = spaces.select{|s| s.french_cubes == 0 and s.algerian_cubes < 3 }
      tmp.shuffle!
      tmp.sort! {|a,b|
        r = b.algerian_police <=> a.algerian_police               # police first
        r = b.algerian_troops <=> a.algerian_troops if r == 0     # troops then
        r
      }

      # up to 2 spaces and 2 cubes
      n = 0
      2.times do
        selected = tmp.shift
        break if selected.nil? or n >= 2
        n += _remove selected
        spaces.delete selected
      end

      # only place FLN from available
      if n == 0 and @board.available_fln_underground > 0 and not spaces.empty?
          n += _replace spaces[rand(spaces.length)]
      end

      # randomly if one piece was removed or GOV is first eligible
      if n == 1 or not first_eligible? and not spaces.empty?
        n += _remove spaces[rand(spaces.length)]
      end
    end

    def _replace selected
      h = get_action :subvert, 0, selected
      transfer h, 1, :algerian_police, selected, :available
      transfer h, 1, :fln_underground, :available, selected
      apply_action h
      2
    end

    def _remove selected
      h = get_action :subvert, 0, selected
      ap = selected.algerian_police.clamp(0, 2)
      transfer h, ap, :algerian_police, selected, :available if ap > 0
      at = selected.algerian_troops.clamp(0, 2 - ap)
      transfer h, at, :algerian_troops, selected, :available if at > 0
      apply_action h
      ap + at
    end

    ##### EXTORT SPECIAL_ACTIVITY #####
    def extort
      # 1+ POP && (FLN control or country) && (1+ FLN underground or 2+ FLN if 1+ FLN bases and not country)
      spaces = @board.search() {|s| not s.pop0? and (s.fln_control? or s.country?) and s.fln_u_1m? and (s.country? or s.fln_bases_0? or s.fln_u_2m?) }

      # 3+ FLN or 2+ FLN if (0 GOV cubes or 0 FLN base)
      spaces.select{|s| s.guerrillas > 3 or (s.guerrillas > 2 and (s.gov_cubes_0? or s.fln_bases_0?)) }.each do |selected|
        _extort selected
        spaces.delete selected
      end

      # Morocco and Tunisia
      spaces.select{|s| s.country? }.each do |selected|
        _extort selected
        spaces.delete selected
      end

      # if still at 0 resources, everywhere possible
      spaces.each do |selected| _extort selected end if @board.fln_resources == 0
    end

    def _extort selected
      h = get_action :extort, -1, selected
      transfer h, 1, :fln_underground, selected, selected, :fln_active
      apply_action h
    end

    ##### ATTACK OPERATION #####
    PIECES = [:gov_base,:french_troops,:french_police,:algerian_troops,:algerian_police].freeze
    def attack
      spaces = nil
      if not may_conduct_special_activity? :ambush
        # GOV pieces && no FLN bases && 6+ FLN
        spaces = @board.search(:sectors) {|s| s.has_gov? and s.fln_bases_0? and s.guerrillas > 5 }
      else
        # GOV pieces && ((no FLN bases && (6+ FLN or 1+ FLN underground)) || (FLN bases and 2+ FLN underground))
        spaces = @board.search(:sectors) {|s| s.has_gov? and ((s.fln_bases_0? and (s.guerrillas > 5 or s.fln_u_1m?)) or (not s.fln_bases_0? and s.fln_u_2m?)) }
      end
      casualties = _compute_casualties spaces
      if casualties.inject(0){|n,c| n + c[:french_police] + c[:french_troops] + c[:gov_base] } > 2
        casualties.each {|c| puts spaces[c[:i]].name; puts c.inspect } if @debug
        ambushes = 0
        casualties.each do |c|
          break if not may_continue?
          a = c[:n] < 5
          next if a and ambushes == 2   # only 2 ambushes
          selected = spaces[c[:i]]
          h = get_action :attack, 1, selected
          if a
            ambushes += 1
            h[:action] = :ambush
            transfer h, 1, :fln_underground, selected, selected, :fln_active
          else
            transfer h, selected.fln_underground, :fln_underground, selected, selected, :fln_active if selected.fln_underground > 0
          end
          PIECES.each {|k| transfer h, c[k], k, selected, :casualties if c[k] != 0 }
          if !a
            fc = c[:french_police] + c[:french_troops] + c[:gov_base]
            fc.times {|t| transfer h, 1, :fln_active, selected, (t%2 == 0 ? :available : :casualties), :fln_underground }
          end
          apply_action h
        end

        if may_continue?
          # GOV pieces && 3+ FLN underground
          spaces = @board.search(:sectors) {|s| s.has_gov? and s.guerrillas > 3 }.select{|s| not_selected s }
          if not spaces.empty?
            c = _compute_casualties(spaces)[0]
            selected = spaces[c[:i]]
            h = get_action :attack, 1, selected
            transfer h, selected.fln_underground, :fln_underground, selected, selected, :fln_active if selected.fln_underground > 0
            if rand(7) <= selected.fln
              PIECES.each {|k| transfer h, c[k], k, selected, :casualties if c[k] != 0 }
              fc = c[:french_police] + c[:french_troops] + c[:gov_base]
              fc.times {|t| transfer h, 1, :fln_active, selected, (t%2 == 0 ? :available : :casualties), :fln_underground }
            end
            apply_action h
          end
        end

        extort if may_conduct_special_activity? :extort

        return conducted_action
      end

      return _march_or_rally
    end

    def _compute_casualties spaces
      casualties = spaces.inject([]) {|n,s|
        h = {:i=>n.length, :n=>s.fln, :u=>s.fln_underground}
        PIECES.each {|k| h[k] = 0 }
        t = 0
        if s.guerrillas > 5    # auto succes -> 2 casualties
          t  = h[:french_police] = s.french_police.clamp(0, 2)
          t += h[:algerian_police] = s.algerian_police.clamp(0, 2 - t) if t < 2
          t += h[:french_troops] = s.french_troops.clamp(0, 2 - t) if t < 2
          t += h[:algerian_troops] = s.algerian_troops.clamp(0, 2 - t) if t < 2
          t += h[:gov_base] = s.gov_bases.clamp(0, 2 - t) if t < 2
        else            # ambush 1 casualty
          t = h[:french_police] = 1 if s.french_police > 0
          t = h[:algerian_police] = 1 if s.algerian_police > 0 and t == 0
          t = h[:french_troops] = 1 if s.french_troops > 0 and t == 0
          t = h[:algerian_troops] = 1 if s.algerian_troops > 0 and t == 0
          t = h[:gov_base]  = 1 if s.fln_bases > 0 and t == 0
        end
        h[:t] = t
        n << h
      }
      casualties.shuffle!
      casualties.sort!{|a,b|
        r = b[:gov_base]  <=> a[:gov_base]                      # bases
        r = b[:french_troops] <=> a[:french_troops] if r == 0   # french troops
        r = b[:french_police] <=> a[:french_police] if r == 0   # french police
        r = b[:t]  <=> a[:t] if r == 0                          # most pieces
        r
      }
      casualties
    end

    ##### MARCH OPERATION #####
    def march
      # up to 2/3 resources expended unless 8 or less resources
      rcs_max = (@board.fln_resources <= 8 ? @board.fln_resources : @board.fln_resources * 2 / 3)
      stop_cond = -> { @expended_resources == rcs_max or not may_continue? }

      # FIXME
      # @board.spaces_h['Tlemcen'].add :fln_underground, -1
      # @board.spaces_h['Tlemcen'].add :fln_base, 1
      # @board.spaces_h['Mascara'].add :fln_underground, 2
      # @board.spaces_h['Mascara'].add :fln_active, 2
      # @board.spaces_h['Saida'].add :fln_base
      # @board.spaces_h['Saida'].add :fln_underground, 1
      # @board.spaces_h['Saida'].add :fln_active, 2
      # @board.spaces_h['Sidi Bel Abbes'].add :algerian_police, 1
      @board.spaces_h['Bordj Bou Arreridj'].add :fln_base, 1
      @board.spaces_h['Oum El Bouaghi'].add :fln_base, 1
      # @board.spaces_h['Biskra'].add :fln_base, 1
      @board.spaces_h['Tebessa'].add :fln_active, 1
      @board.spaces_h['Negrine'].add :fln_active, 1
      @board.spaces_h['Negrine'].add :fln_underground, 1
      #
      spaces = @board.search {|s| not s.fln_bases_0? and s.fln_underground == 0 }
      puts "spaces :: " + spaces.collect(){|s| s.is_a?(Symbol) ? s.to_s : s.name}.join(' :: ')
      selected = spaces[0]
      selected = @board.spaces[11]
      puts "DEST : #{selected.name}"
      d = _paths(selected, {:fln_underground=>1}) {|h| h[:fln_underground] > 0 }

      puts "FIXME : march is not implemented yet"
      exit 1

      # DEAD ZONE => no multiple march

      # march with underground -> unless march will trigger active
      #
      # unless limited ope can march again untill cross wilaya or border
      #
      # pay per destination
      #

      ########
      # march 1 underground FLN to each base that does not have 1
      #  - lowest cost
      # while not stop_cond.call
      #   spaces = @board.search {|s| not s.fln_bases_0? and s.fln_underground == 0 }
      #   break if spaces.empty?
      # end


      ########
      # march 1 FLN to each spaces at Support if 0 FLN
      # march 2 FLN in up to 1 city if Amateur Bombers in effect
      #  - to stay underground : unless last Campaign
      #  - lowest cost

      ########
      # march to remove GOV control in 1 POP+ not at Oppose
      #  - mountain
      #  - highest POP
      #  - lowest cost

      ########
      # march 3 FLN to non-resettled POP0 with room for a base
      #  - fewest GOV cubes
      #  - mountain
      #  - lowest cost
      #  - at least 1 FLN stays underground

      # selected = @board.spaces[11]
      # puts "DEST : #{selected.name}"
      # d = _paths(selected, {:fln_underground=>1}) {|h| h[:fln_underground] > 0 }

      return conducted_action
    end

    def _paths dst, want, &cond
      ws = dst.adjacents.map {|s| @board.spaces[s].wilaya }.uniq!       # adjacent Wilayas allowed
      puts ws.inspect
      spaces = @board.search{|s| s != dst and ws.include? s.wilaya }    # in tree spaces
      puts spaces.collect{|s| s.name }.join(' :: ')
      tree = build_tree dst, spaces, want
      tree.sort{|(x,a),(y,b)| a[:d]<=>b[:d]}.each{|k,v| puts "\t#{v[:d]} #{v[:fln][:max]}:#{v[:fln][:ok]} #{k.name} :: #{v[:adjs].map{|s| s.name}.join(' - ')}" }
    end

    ##### RALLY OPERATION #####
    def rally
      # max 6 spaces unless ope_only => 1
      selected_max = (limited_ope_only? ? 1 : 6)
      # up to 2/3 resources expended unless 8 or less resources
      rcs_max = (@board.fln_resources <= 8 ? @board.fln_resources : @board.fln_resources * 2 / 3)
      stop_cond = -> { @selected_spaces.length == selected_max or @expended_resources == rcs_max or not may_continue? }

      while not stop_cond.call and @board.available_fln_bases > 0
        puts ':: may add fln && 3+ FLN && 0 GOV cubes (unless Limited OP)' if @debug
        break if not _place_base @board.search {|s| may_add_fln_base?(s) and s.guerrillas >= 3 and (limited_ope_only? ? true : s.gov_cubes_0?) and not_selected s }
      end

      while not stop_cond.call and @board.available_fln_bases > 0
        puts ':: may add fln && 4+ FLN' if @debug
        break if not _place_base @board.search {|s| may_add_fln_base?(s) and s.guerrillas >= 4 and not_selected s }
      end

      while not stop_cond.call or not has_fln_to_place?
        puts ':: FLN base && ((1+ pop && 1- underground FLN) or ((0 pop || country) && 0 underground FLN))' if @debug
        spaces = @board.search(:sectors) {|s| s.fln_bases_1m? and ((not s.pop0? and s.fln_u_1l?) or ((s.pop0? or s.country?) and s.fln_u_0?)) and not_selected s }
        break if not _place_fln_1 spaces
      end

      if not stop_cond.call
        puts ':: only once : shift France track towards F' if @debug
        _shift_france_track
      end

      while not stop_cond.call and has_fln_to_place?
        puts ':: non City && Support && 0 underground FLN' if @debug
        break if not _place_fln_2 @board.search(:sectors) {|s| not (s.city? and s.support?) and s.fln_u_0? and not_selected s }
      end

      if not @expended_resources == rcs_max and may_continue?
        puts ':: (FLN control or Base) and 2+ pop && not oppose' if @debug
        rcs = (rcs_max - @expended_resources)
        @expended_resources += _reserve_agitate rcs, @board.search(:sectors) {|s| may_agitate? s and s.pop >= 2 and not_selected s }
      end

      2.times do
        break if stop_cond.call or not has_fln_to_place?
        puts ':: anywhere' if @debug
        break if not _place_fln_3 @board.search() {|s| not_selected s }
      end

      2.times do
        break if stop_cond.call or not has_fln_to_place?
        puts ':: no FLN base but 1+ FLN' if @debug
        break if not _place_fln_4 @board.search() {|s| s.fln_bases_0? and s.guerrillas >= 1 and not_selected s }
      end

      if @agitate.nil? and may_continue?
        puts ':: (FLN control or Base) && not oppose' if @debug
        rcs = (rcs_max - @expended_resources)
        @expended_resources += _reserve_agitate rcs, @board.search(:sectors) {|s| may_agitate? s }
      end

      _agitate @agitate if not @agitate.nil? and may_continue?

      if @debug
        puts "=> Rally done :\n\texpended resources : #{@expended_resources} #{}"
        puts "\tselected spaces :: " + @selected_spaces.collect(){|s| s.is_a?(Symbol) ? s.to_s : s.name}.join(' :: ')
      end

      subvert if may_conduct_special_activity? :subvert
      extort if may_conduct_special_activity? :extort

      return conducted_action
      # FIXME if NONE => MARCH
    end

    def _place_base spaces
      return false if spaces.empty?
      puts '  => place_base' if @debug
      selected = spaces[rand(spaces.length)]
      a = selected.fln_active.clamp(0,2)
      u = a < 2 ? 2 - a : 0
      h = get_action :rally, 1, selected
      transfer h, a, :fln_active, selected, :available, :fln_underground if a != 0
      transfer h, u, :fln_underground, selected, :available if u != 0
      transfer h, 1, :fln_base, :available, selected
      apply_action h
    end

    def _reserve_agitate max_cost, spaces
      spaces.select!{|s| not not_selected s } if not has_fln_to_place?
      spaces.select!{|s| (s.terror + 1 + (not_selected(s) ? 1 : 0)) <= max_cost }
      return 0 if spaces.empty?
      spaces.shuffle!
      spaces.sort! {|a,b|
        r = b.pop <=> a.pop                                                   # most population
        r = a.terror <=> b.terror if r == 0                                   # less terror
        r = (a.support? ? 0 : 1) <=> (b.support? ? 0 : 1) if r == 0           # support
        r = (not_selected(a) ? 1 : 0) <=> (not_selected(b) ? 1 : 0) if r == 0 # already selected
        r
      }
      @agitate = spaces[0]
      _place_fln [@agitate] if not_selected @agitate
      @agitate.terror + 1
    end

    def _agitate selected
      puts '  => agitate' if @debug
      h = get_action :agitate, selected.terror + 1, selected, false
      h[:already_expended] = true
      h[:markers] =[ [:alignment, 1, :oppose, selected.alignment, (selected.support? ? :neutral : :oppose)] ]
      if selected.terror > 0
        h[:markers].insert(0, [:terror, -selected.terror, nil, selected.terror, 0])
        @board.terror selected, -selected.terror
      end
      @board.shift selected, :oppose
      apply_action h
    end

    def _place_fln_1 spaces
      return false if spaces.empty?
      puts '  => place_fln_1' if @debug
      spaces = try_filter(spaces) {|s| not s.country? }     # in Algeria
      spaces = try_filter(spaces) {|s| not s.gov_cubes_0? } # with GOV cubes
      spaces = try_filter(spaces) {|s| not s.pop0? }        # POP 1+
      spaces.shuffle!
      spaces.sort! do |a,b|
        r = a.fln_underground <=> b.fln_underground         # least underground FLN
        r = b.fln_active <=> b.fln_active if r == 0         # most active FLN
        r
      end
      a = spaces[0].fln_underground
      b = spaces[0].fln_active
      spaces.select!{|s| s.fln_underground==a and s.fln_active==b }
      _place_fln spaces
    end

    def _place_fln_2 spaces
      return false if spaces.empty?
      puts '  => place_fln_2' if @debug
      spaces = sort_filter(spaces, :pop)                    # highest POP
      _place_fln spaces
    end

    def _place_fln_3 spaces
      return false if spaces.empty?
      puts '  => place_fln_3' if @debug
      spaces = try_filter(spaces) {|s| s.uncontrolled? and (s.pop + 1).clamp(0, n) > (s.gov_cubes + s.gov_bases) }     # may gain FLN control
      spaces = try_filter(spaces) {|s| s.gov_control? and (s.pop + 1).clamp(0, n) > (s.gov_cubes + s.gov_bases) }     # may remove GOV control
      spaces = try_filter(spaces) {|s| ['II','IV','V'].include? s.wilaya }                                            # Wilaya with a city
      spaces = sort_filter(spaces, :terror, :asc)                                                                     # least terror markers
      _place_fln spaces
    end

    def _place_fln_4 spaces
      return false if spaces.empty?
      puts '  => place_fln_4' if @debug
      spaces = try_filter(spaces) {|s| not s.country? }     # in Algeria
      spaces = sort_filter(spaces, :fln)                    # most FLN
      spaces = try_filter(spaces) {|s| s.gov_cubes_0? }     # no Government cubes
      _place_fln spaces
    end

    def _place_fln spaces
      puts "\t spaces :: " + spaces.collect(){|s| s.is_a?(Symbol) ? s.to_s : s.name}.join(' - ') if @debug
      spaces = try_filter(spaces) {|s| s.support? }         # Support spaces 8.1.2#4
      spaces = try_filter(spaces) {|s| s.guerrillas > 0 }   # friendly 8.1.2#4
      spaces.shuffle!
      while not spaces.empty?
        selected = spaces.shift
        n = fln_to_place.clamp(0, (selected.pop + 1 - selected.fln))  # at most POP + 1
        if n == 0 # will only flip underground if #FLN at POP + 1
          next if selected.fln_active == 0              # will not flip 0 active FLN
          transfer h, selected.fln_active, :fln_active, selected, selected, :fln_underground
          return apply_action h
        end
        m = n.clamp(0, @board.available_fln_underground)
        h = get_action :rally, 1, selected
        transfer h, m, :fln_underground, :available, selected
        while m < n
          # leave at least 2 FLN at FLN base or support
          actives = @board.search(:sectors) {|s| (not s.fln_bases_0? or s.support?) ? s.fln_active > 2 : s.fln_active > 0 }
          actives = sort_filter(actives, :fln)      # the most active
          space = actives.shift
          q = space.fln_active
          q -= 2 if not space.fln_bases_0? or space.support?
          q = q.clamp(1, n)
          transfer h, q, :fln_active, space, selected, :fln_underground
          m += q
        end
        return apply_action h
      end
      false
    end

    def _shift_france_track
      h = get_action :rally, 1, :france_track, false
      return false if not @board.shift_france_track 1
      puts '  => shift_france_track' if @debug
      h[:france_track] = @board.france_track
      apply_action h
    end

    ##### ACTIONS #####

    def get_action action, cost, selected, t=true
      h = { :action => action,
            :fln_resources => cost,
            :selected => selected,
            :controls => {}
      }
      h[:transfers] = [] if t
      h
    end

    def transfer h, n, what, from, to, towhat=nil
      towhat = what if towhat.nil?
      h[:controls][from] ||= from.control unless from.is_a? Symbol
      h[:controls][to] ||= to.control unless to.is_a? Symbol
      @board.transfer n, what, from, to, towhat
      h[:transfers] << { :n => n, :what => what, :from=>from, :to => to, :towhat=> towhat }
      # puts h[:transfers][-1] if @debug
    end

    # def revert_transfers h
    #   h[:transfers].each do |tr|
    #     @board.transfer tr[:n], tr[:towhat], tr[:to], tr[:from], tr[:what]
    #   end
    # end

    OPERATIONS = [:rally, :march, :attack, :terror].freeze
    SPECIAL_ACTIVITIES = [:extort, :subvert, :ambush, :oas].freeze
    IGNORE = [:pass, :event, :agitate].freeze

    def apply_action h
      action = h[:action]
      if OPERATIONS.include? action
        operation_done action
        raise "already selected #{h[:selected].name}" if @selected_spaces.include? h[:selected]
        @selected_spaces << h[:selected] #unless @selected_spaces.include? h[:selected]
        puts 'selected spaces :: ' + @selected_spaces.collect(){|s| s.is_a?(Symbol) ? s.to_s : s.name}.join(' :: ') if @debug
      elsif SPECIAL_ACTIVITIES.include? action
        special_activity_done action
        @selected_spaces << h[:selected] if action == :ambush
      elsif not IGNORE.include? action
        raise "apply unknown action #{h[:action]}"
      else
        # :pass, :event, :agitate
      end
      cost = h[:fln_resources]
      @board.fln_resources -= cost
      @expended_resources += cost unless h.has_key? :already_expended # _reserve_agitate
      h[:resources] = {:cost=>cost, :value=>@board.fln_resources}
      h[:controls].each do |k,v|
        if v != k.control
          h[:controls][k] = [v, k.control]
        else
          h[:controls].delete k
        end
      end
      @ui.show_player_action self, h
      true
    end

    #### HELPERS ####

    def may_continue?
      return false if limited_ope_done?
      return true if @board.fln_resources > 0
      return false if not may_conduct_special_activity? :extort
      puts "\t=> pause to extort" if @debug
      extort
      return @board.fln_resources > 0
    end

    def has_fln_to_place?
      fln_to_place > 0
    end

    def fln_to_place
      (@board.available_fln_underground + @board.count() {|s| s.fln_active })
    end

    def may_agitate? s
        (s.fln_control? or s.fln_bases_1m?) and not s.oppose?
    end

    def may_add_fln_base? s
      # return false if (s.support? and s.city?) coltwi ?
      # max 1 base in Algeria AND at least 1 underground FLN
      (s.fln_bases < (s.country? ? s.max_bases : 1)) and (s.fln_underground > 0)
    end

    def activate to, from, flns
      # goes active if moved into Support or crossed International Border && #FLN + GOV cubes (+border) > 3
      ( (to.support? or from.country?) and (flns + to.gov_cubes + (from.country? ? @board.border_zone_track : 0)) > 3 )
    end

    def build_tree dst, spaces, want
      tree = ([dst] + spaces).inject({}) do |h,s|
        # filter out adjacents : dst OR adjacent to dst OR same wilaya
        a = s.adjacents.map{|n| @board.spaces[n]}.select{|a| a == dst or (spaces.include?(a) and (s.wilaya == a.wilaya or s == dst))}
        h[s] = { :adjs=> a, :fln => can_march_from(s, want), :d => 0}
        h
      end
      q = [dst]
      while not q.empty?
        s = q.shift
        h = tree[s]
        d = h[:d] + 1
        h[:adjs].each do |a|
          next if a == dst
          p = tree[a][:d]
          if p == 0 or d < p
            tree[a][:d] = d
            q << a
          end
        end
      end
      tree
    end

    def can_march_from s, want, with={}
      u = s.fln_underground + (with[:fln_underground]||0)
      a = s.fln_active + (with[:fln_active]||0)
      d = 0
      if not s.fln_bases_0?
        # at bases, leave last underground FLN, leave 2 FLN
        if u > 0
          u -= 1
          d = 1
        else
          a = (a > 2 ? a - 2 : 0)
        end
      end
      if (s.fln_bases_0? and s.support?) or d == 1
        # march with underground FLN, that could be swaped with an active FLN
          d = ((a > 0 and u > 0) ? 1 : 0)
          if a > 0
            a -= 1
          elsif u > 0
            u -= 1
          end
      end
      # never trigger GOV Control on populated spaces
      max = [(not s.country? and not s.pop0? and not s.gov_control?) ? (s.fln - s.gov) : 666, u + a].min
      # does it satisfy want conditions
      ok = (u >= (want[:fln_underground]||0) and a >= (want[:fln_active]||0) and max >= (want[:fln]||1))
      { :fln_underground=>u, :fln_active=>a, :delta=>d, :max=>max, :ok=>ok }
    end

    def last_campaign?
      false # FIXME
    end

    def possible_extort
      # FIXME : if resources at 0 and no spaces
      # 1+ POP && (FLN control or country) && (1+ FLN underground or 2+ FLN if 1+ FLN bases)
      spaces = @board.search() {|s| not s.pop0? and (s.fln_control? or s.country?) and s.fln_u_1m? and (s.country? or s.fln_bases_0? or s.fln_u_2m?) }
      spaces.inject(0) {|n,s| n + s.fln_underground - ((not s.fln_bases_0? and not s.country?) ? 1 : 0) }
    end

    def pacifiable? s
      # FIXME if Recall de Gaulle 8.4.2 third bullet point
      not s.country? and (not s.gov_bases_0? or (s.troop >= 1 and s.police >= 1 and s.gov_control?))
    end

    ##### FILTERS #####

    def not_selected s
      not @selected_spaces.include? s
    end

    def try_filter list, &block
      filtered = list.select &block
      (filtered.empty? ? list : filtered)
    end

    def sort_filter spaces, sym, order=:desc
      spaces.shuffle!
      if order == :desc
        spaces.sort! {|a,b| b.send(sym) <=> a.send(sym) }
      else
        spaces.sort! {|a,b| a.send(sym) <=> b.send(sym) }
      end
      v = spaces[0].send(sym)
      spaces.select {|s| s.send(sym) == v }
    end

  end

end
