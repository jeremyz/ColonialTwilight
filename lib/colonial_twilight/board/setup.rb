# frozen_string_literal: true

module ColonialTwilight
  module Setup
    def setup
      set_spaces
      set_adjacents
    end

    def add(kls, *args)
      @spaces << kls.new(*args)
    end

    def set_spaces
      mountain = Sector::MOUNTAIN
      border = Sector::BORDER
      coastal = Sector::COASTAL
      add Sector, 'Barika', 'I', 1, 1, mountain
      add Sector, 'Batna', 'I', 2, 0, mountain
      add Sector, 'Biskra', 'I', 3, 0, border
      add Sector, 'Oum El Bouaghi', 'I', 4, 0, mountain
      add Sector, 'Tebessa', 'I', 5, 1, mountain | border
      add Sector, 'Negrine', 'I', 6, 0, mountain | border
      add City, 'Constantine', 'II', 2
      add Sector, 'Setif', 'II', 1, 1, mountain | coastal
      add Sector, 'Philippeville', 'II', 2, 2, mountain | coastal
      add Sector, 'Souk Ahras', 'II', 3, 2, coastal | border
      add Sector, 'Tizi Ouzou', 'III', 1, 2, mountain | coastal
      add Sector, 'Bordj Bou Arreridj', 'III', 2, 1, mountain
      add Sector, 'Bougie', 'III', 3, 2, mountain | coastal
      add City, 'Algiers', 'IV', 3, coastal
      add Sector, 'Medea', 'IV', 1, 2, mountain | coastal
      add Sector, 'Orleansville', 'IV', 2, 2, mountain | coastal
      add City, 'Oran', 'V', 2, coastal
      add Sector, 'Mecheria', 'V', 1, 0, mountain | border
      add Sector, 'Tlemcen', 'V', 2, 1, border | coastal
      add Sector, 'Sidi Bel Abbes', 'V', 3, 1, coastal
      add Sector, 'Mostaganem', 'V', 4, 2, mountain | coastal
      add Sector, 'Saida', 'V', 5, 0, mountain
      add Sector, 'Mascara', 'V', 6, 0, mountain
      add Sector, 'Tiaret', 'V', 7, 0, mountain
      add Sector, 'Ain Sefra', 'V', 8, 0, border
      add Sector, 'Laghouat', 'V', 9, 0
      add Sector, 'Sidi Aissa', 'VI', 1, 0, mountain
      add Sector, 'Ain Oussera', 'VI', 2, 1, mountain
      add Country, 'Morocco'
      add Country, 'Tunisia'
    end

    def adjacents(name, *args)
      by_name(name).adjacents = args
    end

    def set_adjacents
      adjacents 'Barika', 1, 2, 3, 7, 8, 11, 26
      adjacents 'Batna', 0, 2, 3, 5
      adjacents 'Biskra', 0, 1, 5, 25, 26, 29
      adjacents 'Oum El Bouaghi', 0, 1, 4, 5, 8, 9
      adjacents 'Tebessa', 3, 5, 9, 29
      adjacents 'Negrine', 1, 2, 3, 4, 29
      adjacents 'Constantine', 7, 8
      adjacents 'Setif', 0, 6, 8, 11, 12
      adjacents 'Philippeville', 0, 3, 7, 6, 9
      adjacents 'Souk Ahras', 3, 4, 8, 29
      adjacents 'Tizi Ouzou', 11, 12, 14
      adjacents 'Bordj Bou Arreridj', 0, 7, 10, 12, 14, 26
      adjacents 'Bougie', 7, 10, 11
      adjacents 'Algiers', 14
      adjacents 'Medea', 10, 11, 13, 15, 26, 27
      adjacents 'Orleansville', 14, 20, 23, 27
      adjacents 'Oran', 19
      adjacents 'Mecheria', 18, 21, 24, 28
      adjacents 'Tlemcen', 17, 19, 21, 28
      adjacents 'Sidi Bel Abbes', 16, 18, 20, 21, 22
      adjacents 'Mostaganem', 15, 19, 22, 23
      adjacents 'Saida', 17, 18, 19, 22, 24
      adjacents 'Mascara', 19, 20, 21, 23, 24
      adjacents 'Tiaret', 15, 20, 22, 24, 27
      adjacents 'Ain Sefra', 17, 21, 22, 23, 25, 27, 28
      adjacents 'Laghouat', 2, 24, 26, 27
      adjacents 'Sidi Aissa', 0, 2, 11, 14, 25, 27
      adjacents 'Ain Oussera', 14, 15, 23, 24, 25, 26
      adjacents 'Morocco', 17, 18, 24
      adjacents 'Tunisia', 2, 4, 5, 9
    end
  end
end
