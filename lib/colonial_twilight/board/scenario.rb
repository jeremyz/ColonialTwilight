# frozen_string_literal: true

module ColonialTwilight
  module Scenario
    def resettle(name)
      by_name(name).resettle!
    end

    def set_space(idx, opts, align = nil)
      s = @spaces[idx]
      s.alignment = align unless align.nil?
      %i[gov_bases fln_bases french_troops french_police algerian_troops algerian_police
         fln_underground].each { |sym| s.add(sym, opts[sym]) if opts.key?(sym) }
    end

    def short_scenario
      @opposition_bases.v = 19
      @support_commitment.v = 22
      @commitment.v = 15
      @fln_resources.v = 15
      @gov_resources.v = 20
      @france_track.v = 4
      @border_zone_track.v = 3
      @out_of_play.init(fln_underground: 5)
      @available.init(gov_bases: 2, french_police: 4, fln_bases: 7, fln_underground: 8)
      resettle 'Setif'
      resettle 'Tlemcen'
      resettle 'Bordj Bou Arreridj'

      set_space  0, { algerian_police: 1, fln_underground: 1 }, :oppose
      set_space  2, { french_police: 1 }
      set_space  4, { algerian_police: 1, fln_underground: 1 }, :oppose
      set_space  5, { french_police: 1 }
      set_space  6, { french_police: 1 }, :support
      set_space  7, { fln_underground: 1 }
      set_space  8, { french_troops: 4, algerian_police: 1, gov_bases: 1 }
      set_space  9, { french_troops: 1, algerian_police: 1, gov_bases: 1, fln_underground: 1, fln_bases: 1 }, :oppose
      set_space 10, { french_police: 1, fln_underground: 1, fln_bases: 1 }, :oppose
      set_space 11, { french_police: 1 }
      set_space 12, { french_police: 1, fln_underground: 1, fln_bases: 1 }, :oppose
      set_space 13, { french_troops: 4, algerian_troops: 1, french_police: 1 }, :support
      set_space 14, { algerian_troops: 1, gov_bases: 1 }
      set_space 15, { french_police: 1, algerian_police: 1, fln_underground: 1, fln_bases: 1 }, :oppose
      set_space 16, { algerian_troops: 1, french_police: 1, algerian_police: 1 }, :support
      set_space 17, { french_police: 1, algerian_police: 1 }
      set_space 18, { french_police: 2, fln_underground: 1 }
      set_space 19, { french_police: 1, gov_bases: 1 }
      set_space 20, { french_police: 1 }
      set_space 22, { french_police: 1 }
      set_space 23, { french_police: 1 }
      set_space 24, { french_police: 1 }
      set_space 27, {}, :oppose
      set_space 28, { fln_underground: 4, fln_bases: 2 }
      set_space 29, { fln_underground: 5, fln_bases: 2 }
      spaces[28].independent!
      spaces[29].independent!
    end

    def medium_scenario
      raise 'MEDIUM scenario net implemented yet'
    end

    def full_scenario
      raise 'FULL scenario net implemented yet'
    end
  end
end
