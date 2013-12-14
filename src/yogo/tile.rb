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
      @data = { :height => 0.0,
                :water_pollution => 0.0,
                :air_pollution => 0.0
      }
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
      t = TERRAIN[@data[:terrain]] || 'Water'
      if @data[:structure] then
        t = "#{t} (#{@data[:structure].name})"
      end
      t
    end

    def resource_name
      TERRAIN[@data[:resource]]
    end

    def valid_structures
      return [] if @data[:structure]
      list = []
      case @data[:terrain]
      when :grass, :hills, :mountains
        list += [ :farm, :factory, :power_station ]
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
