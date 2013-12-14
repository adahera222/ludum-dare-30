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

    def valid_structures
      list = []
      case @data[:terrain]
      when :grass, :hills, :mountain
        list += [ :factory, :power_station ]
        list << :mine if [ :coal, :iron, :aluminium, :uranium ].include?(@data[:resource])
        list << :well if @data[:resource] == :oil
      else
        list << :fishing_fleet if @data[:resource] == :fish
        list << :platform if @data[:resource] == :oil
      end
      list
    end

  end
end
