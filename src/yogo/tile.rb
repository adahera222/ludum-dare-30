module YOGO
  class Tile
    NEIGHBOURS = [ -1, 0, 1].product([-1,0,1]) - [0,0]

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

    SPREAD_DIVISORS = {
                        # Water pollution has a hard time flowing up hill
                        # It also flows through any ground with
                        # difficulty
                        :water_pollution => { :grass => 2.0,
                                              :hills => 3.0,
                                              :mountain => 5.0
                                            },
                        # Air pollution flows across grassland easily,
                                            # and even easier out to sea
                        :air_pollution => {
                                              :water => 0.75,
                                              :mountain => 10.0,
                                              :hills => 2.0
                                            }
                      }

    def initialize(pos)
      @pos = pos
      @data = { :terrain => :water,
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

    def structure
      @data[:structure]
    end

    def terrain
      @data[:terrain]
    end

    def [](property)
      @data[property]
    end

    def []=(property, value)
      @data[property] = value
    end

    def terrain_name
      t = TERRAIN[terrain] || 'Water'
      if structure then
        t = "#{t} (#{structure.name})"
      end
      t
    end

    def resource_name
      TERRAIN[@data[:resource]]
    end

    def valid_structures
      return [] if structure
      list = []
      case terrain
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

    def update(map)
      if structure then
        structure.update(map)
      end
      # TODO: Pollution spreads out to tiles with lesser
      air_spread = []
      water_spread = []
      NEIGHBOURS.each do |offset|
        neighbour = map[[x + offset[0], y + offset[1]]]
        next if neighbour.nil?
        air_spread << neighbour if neighbour[:air_pollution] < @data[:air_pollution]
        water_spread << neighbour if neighbour[:water_pollution] < @data[:water_pollution]
      end

      spread(:air_pollution, air_spread)
      spread(:water_pollution, water_spread)
    end

  private

    def spread(prop, victims)
      victims.each do |tile|
        delta = @data[prop] - tile[prop]
        spread = delta / (victims.length + 1).to_f
        divisor = SPREAD_DIVISORS[prop][tile.terrain] || 1.0
        spread = spread / divisor
        next if spread < 0.01
        tile[prop] += spread
        @data[prop] -= spread

        # puts "Moved #{spread} #{prop} from #{@pos.inspect} (#{@data[prop].inspect} to #{tile.pos.inspect} (#{tile[prop].inspect})"
      end
    end

  end
end
