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
                                            },
                        :inundation =>      { :hills => 3.0,
                                              :mountain => 5.0
                                            }
                      }

    POLLUTION_DESCRIPTIONS = {
      :water_pollution => { 0.05 => 'Pristine water',
                            0.15 => 'Minor water pollution',
                            0.20 => 'Some water pollution',
                            0.50 => 'Heavy water pollution',
                            0.75 => 'Toxic sludge',
                            2.00 => 'Raw toxic waste'
                          },
      :air_pollution =>   { 0.05 => 'Pristine air',
                            0.15 => 'Minor dust particles',
                            0.20 => 'Some air pollution',
                            0.50 => 'Heavy air pollution',
                            0.75 => 'Noxious fumes',
                            2.00 => 'Toxic fumes'
                          }
    }

    def initialize(pos)
      @pos = pos
      @data = { :terrain => :water,
                :water_pollution => 0.0,
                :air_pollution => 0.0,
                :inundation => 0.0
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

    def resource
      @data[:resource]
    end

    def air_pollution
      @data[:air_pollution]
    end

    def water_pollution
      @data[:water_pollution]
    end

    def inundation
      @data[:inundation]
    end

    def air_pollution_description
      pollution_description(:air_pollution, air_pollution)
    end

    def water_pollution_description
      pollution_description(:water_pollution, water_pollution)
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

    def update(world)
      if structure then
        structure.update(world)
      end

      if terrain == :water then
        @data[:inundation] += 0.01 # Total inundation at ~400 turns, ~30 years at max rate.
      else
        if inundation > 0.5 then
          @data[:terrain] = :water
          @data[:resource] = nil if [ :uranium, :coal, :aluminium, :iron_ore, :arable ].include?(@data[:resource])
          @data[:inundation] = 0.0
        end
      end

      # Pollution spreads out to tiles with lesser
      air_spread = []
      water_spread = []
      inundation_spread = []
      NEIGHBOURS.each do |offset|
        neighbour = world.map[[x + offset[0], y + offset[1]]]
        next if neighbour.nil?
        air_spread << neighbour if neighbour.air_pollution < air_pollution
        water_spread << neighbour if neighbour.water_pollution < water_pollution
        inundation_spread << neighbour if neighbour.terrain != :water && neighbour.inundation < inundation
      end

      spread(:air_pollution, air_spread)
      spread(:water_pollution, water_spread)
      spread(:inundation, inundation_spread)

      # When tiles reach a threshold, they can loose their bonuses
      @data[:resource] = nil if resource == :arable && (air_pollution > 0.75 || water_pollution > 0.25)
      @data[:resource] = nil if resource == :fish && water_pollution > 0.20

      @data[:air_pollution] = 1.0 if air_pollution > 1.0
      @data[:water_pollution] = 1.0 if water_pollution > 1.0
    end

  private

    def pollution_description(type, value)
      POLLUTION_DESCRIPTIONS[type].each do |limit, name|
        return "#{name} #{sprintf('%.2f', value)}" if value <= limit
      end
    end

    def spread(prop, victims)
      orig = @data[prop]
      victims.each do |tile|
        delta = orig - tile[prop]
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
