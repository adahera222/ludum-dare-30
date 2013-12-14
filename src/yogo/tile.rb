module YOGO
  class Tile

    attr_reader :pos

    TERRAIN = { :grass => 'Grassland',
                :hills => 'Hills',
                :mountains => 'Mountains',
                :swamp => 'Swamp',
                :oil => 'Oil',
                :coal => 'Coal',
                :iron => 'Iron Ore',
                :uranium => 'Uranium',
                :aluminium => 'Aluminium',
                :arable => 'Arable Land'
    }

    def initialize(pos)
      @pos = pos
      @data = { :height => 0.0 }
    end

    def x
      @pos[0]
    end

    def y
      @pos[1]
    end

    def [](property)
      @data[property]
    end

    def []=(property, value)
      @data[property] = value
    end

    def terrain_name
      TERRAIN[@data[:terrain]] || 'Water'
    end

    def resource_name
      TERRAIN[@data[:resource]]
    end

  end
end
