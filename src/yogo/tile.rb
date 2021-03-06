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
                                            },
                        :claims =>          { :water => 5.0,
                                              :mountain => 2.0
                                            }
                      }

    POLLUTION_DESCRIPTIONS = {
      :water_pollution => { 0.05 => 'Pristine',
                            0.15 => 'Minor',
                            0.20 => 'Some',
                            0.50 => 'Heavy',
                            0.75 => 'Toxic',
                            2.00 => 'Raw Waste'
                          },
      :air_pollution =>   { 0.05 => 'Pristine',
                            0.15 => 'Dusty',
                            0.20 => 'Haze',
                            0.50 => 'Smog',
                            0.75 => 'Noxious',
                            2.00 => 'Toxic'
                          }
    }

    def initialize(pos)
      @pos = pos
      @data = { :terrain => :water,
                :water_pollution => 0.0,
                :air_pollution => 0.0,
                :inundation => 0.0,
                :claims => {},
                :state => nil
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

    def state
      @data[:state]
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
      Structure::STRUCTURES.each do |type, klass|
        list << type if klass.respond_to?(:valid_tile?) && klass.valid_tile?(self)
      end
      list
    end

    def update(world)
      if structure then
        structure.update(world)
      end

      if terrain == :water then
        @data[:inundation] += 0.01 * world.warming_rate
        @data[:inundation] = 0.0 if @data[:inundation] < 0.0
        if @data[:air_pollution] >= 0.001
          @data[:air_pollution] -= 0.001
          @data[:water_pollution] += 0.001
        end
        if @data[:water_pollution] >= 0.001
          @data[:water_pollution] -= 0.001
        end
      else
        if inundation > 0.5 then
          @data[:terrain] = :water
          @data[:resource] = nil if [ :uranium, :coal, :aluminium, :iron_ore, :arable ].include?(@data[:resource])
          if structure then
            unless valid_structures.include?(structure.type)
              if structure.owner == world.player then
                world.ui_handler.location_alert("Your #{structure.name} in #{structure.owner.name} was destroyed by rising waters", structure.tile)
              end
              structure.owner.remove_structure(structure)
              @data[:structure] = nil
            end
          end
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
        return "#{name} #{sprintf('%d%%', value * 100.0)}" if value <= limit
      end
    end

    def spread(prop, victims, key=nil, threshold = 0.01)
      if key then
        orig = @data[prop][key]
      else
        orig = @data[prop]
      end
      victims.each do |tile|
        if key then
          delta = orig - (tile[prop][key] || 0.0)
        else
          delta = orig - tile[prop]
        end
        spread = delta / (victims.length + 1).to_f
        divisor = SPREAD_DIVISORS[prop][tile.terrain] || 1.0
        spread = spread / divisor
        next if spread < threshold
        if key then
          tile[prop][key] = (tile[prop][key] || 0.0) + spread
          @data[prop][key] -= spread
        else
          tile[prop] += spread
          @data[prop] -= spread
        end
      end
    end

  end
end
