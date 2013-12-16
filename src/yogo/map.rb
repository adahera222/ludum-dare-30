require 'yogo/tile'
require 'yogo/entity/country'
require 'yogo/entity/corporation'

module YOGO
  class Map

    attr_reader :maxx, :maxy
    attr_accessor :entities
    attr_reader :unmapped

    COUNTRY_COLOURS = [
      Color.new(1.0, 1.0, 1.0, 1.0),
      Color.new(1.0, 0.0, 0.0, 1.0),
      Color.new(0.0, 1.0, 0.0, 1.0),
      Color.new(0.0, 0.0, 1.0, 1.0),
      Color.new(1.0, 1.0, 0.0, 1.0),
      Color.new(1.0, 0.0, 1.0, 1.0),
      Color.new(0.0, 1.0, 1.0, 1.0),
      Color.new(0.1, 0.5, 0.0, 1.0),
      Color.new(0.0, 0.0, 0.5, 1.0),
      Color.new(0.5, 0.0, 0.5, 1.0),
    ]

    def initialize(width, height)
      @maxx = width - 1
      @maxy = height - 1

      @tiles = Hash.new { |hash, pos| hash[pos] = Tile.new(pos) }

      @entities = []

      random!
    end

    def width
      @maxx + 1
    end

    def height
      @maxx + 1
    end

    def [](pos)
      return nil unless in_range?(pos)
      @tiles[pos]
    end

    def in_range?(pos)
      x,y = pos
      (x >= 0 && x <= @maxx) && (y >= 0 && y <= @maxy)
    end

    def opponents_generated?
      @opponents_generated
    end

    def world_gen_update(world)
      if @unmapped > 0 then
        @capitals.each do |capital|
          capital.tile[:claims] ||= {}
          capital.tile[:claims][capital.owner] ||= 0.0
          capital.tile[:claims][capital.owner] += 4000.0
        end
        0.upto(@maxx) do |x|
          0.upto(@maxy) do |y|
            pos = [x,y]
            tile = self[pos]
            tile[:state] = @capitals.sort_by { |capital|
              dx = capital.tile.x - x
              dy = capital.tile.y - y
              (dx ** 2) + (dy ** 2)
            }.first.owner
            @unmapped -= 1
          end
        end
      end
      if !@opponents_generated then
        process_opponent_cycle(world)
      end
    end

    def update(world)
      @entities.each do |entity|
        entity.update(world)
      end
      @tiles.each do |pos, cell|
        cell.update(world)
      end

      @entities.each do |e|
        puts e.to_s if e.is_a?(Entity::Corporation)
      end
    end

    def rand
      self[[ Kernel::rand(@maxx), Kernel::rand(@maxy) ]]
    end

    def build_structure(type, tile, owner)
      s = Structure.create(type, tile)
      s.owner = owner
      tile[:structure] = s
      s
    end

    def find_and_build(structure, owner, resource=nil)
      pos = nil
      while(pos.nil? || (resource && pos.resource != resource) || !pos.valid_structures.include?(structure)) do
        pos = self.rand
      end

      build_structure(structure, pos, owner)
    end

  private

    def random!
      generate_tectonic_plates
      generate_countries_and_capitals
      generate_opponents
    end

    # TODO: Generate random plates and give them a height
    # TODO: Where two plates overlap, decide if it's a +1 or a -1
    def generate_tectonic_plates
      max_radius = (width / 10) * 2.0

      hill_resources = [ :coal, :iron, :uranium ]
      mountain_resources = [ :coal, :iron, :uranium ]

      (width/4).times do
        candidates = { }

        radius = (width / 10) * (1.0 + Kernel::rand)
        pos = [ Kernel::rand(@maxx), Kernel::rand(@maxy) ]
        cx,cy = pos

        tiles = { }

        1.upto(radius) do |r|
          (cx-r).upto(cx+r) do |x|
            (cy-r).upto(cy+r) do |y|
              pos = [x,y]
              next if tiles[pos]
              next unless in_range?(pos)

              if Kernel::rand >= r.to_f/max_radius
                tiles[pos] = true
                tile = self[pos]
                if tile[:terrain] == :grass then
                  tile[:terrain] = :hills
                  tile[:resource] = nil
                  tile[:resource] = hill_resources[Kernel::rand(hill_resources.length - 1)] if Kernel::rand < 0.20
                  tile[:resource] = :arable if tile[:resource].nil? && Kernel::rand < 0.40
                elsif tile[:terrain] == :hills then
                  tile[:terrain] = :mountains
                  tile[:resource] = nil
                  tile[:resource] = mountain_resources[Kernel::rand(mountain_resources.length - 1)] if Kernel::rand < 0.40
                else
                  tile[:terrain] = :grass
                  tile[:resource] = nil
                  tile[:resource] = :arable if Kernel::rand < 0.10
                  tile[:resource] = :oil if Kernel::rand < 0.025
                  tile[:resource] = hill_resources[Kernel::rand(hill_resources.length - 1)] if tile[:resource].nil? && Kernel::rand < 0.05
                end
              end
            end
          end
        end
      end
    end

    def generate_countries_and_capitals
      idx = 1
      min_dist = 2 * ((width/8.0) ** 2)
      @capitals = []
      (width/4).times do |country_id|
        pos = nil
        dist = 0.0

        while pos.nil? || pos.terrain == :water || !pos.resource.nil? || !pos.structure.nil? || dist < min_dist do
          pos = self.rand
          if @capitals.length > 0 then
            dist = @capitals.collect { |other| ((other.tile.x - pos.x) ** 2) + ((other.tile.y - pos.y) ** 2) }.min
          else
            dist = 9999.00
          end
        end

        country = Entity::Country.new
        country.name = "Country #{country_id}"
        country.color = COUNTRY_COLOURS[idx]
        @entities << country

        city = Structure.create(:city, pos)
        city.owner = country
        city.population = 1.0 + Kernel::rand(5.0)
        city.name = country.name
        pos[:structure] = city
        pos[:state] = country

        @capitals << city

        idx += 1
      end

      @unmapped = (width * height) - @capitals.length
      # @unmapped = 0
    end

    def generate_opponents
      @opponents_generated = false

      # Create 6 other opponent corporations
      6.times do |i|
        c = Entity::Corporation.new
        c.name = "Corporation #{i}"
        c.balance = -25.0
        @entities << c
      end
    end

    def process_opponent_cycle(world)
      # TODO: Work through each opponent, turn by turn, fulfilling up to:
      # * 110% of food required
      # * 110% of power required
      # * 100% of steam required

      @entities.each do |entity|
        next unless entity.is_a?(Entity::Corporation)

        # TODO: Calculate what is still demanded, and what is being provided
        demand = {}
        @entities.each do |other|
          other.structures.each do |structure|
            # TODO: Get every Entity and iterate through all their structures
            #       + for every requirement, - for everything they provide
            structure.production.each do |commodity, quantity|
              demand[commodity] = (demand[commodity] || 0.0) - quantity
            end
            structure.consumes.each do |commodity, quantity|
              demand[commodity] = (demand[commodity] || 0.0) + quantity
            end
          end
        end

        puts "CURRENT: #{demand.inspect}"

        # TODO: Pick the greatest, above zero demand
        demand.reject! { |key, value| value <= 0.0 }
        commodity = demand.to_a.sort_by { |el| el[1] }.last

        puts "FILTERED: #{demand.inspect}"

        if commodity.nil? then
          # TODO: Break out if all demands are met, and set @opponents_generated = true
          @opponents_generated = true
          break
        else
          commodity = commodity[0]
        end

        puts "I will produce: #{commodity}"

        # TODO: Build a structure which will fulfil the demand
        struct = case commodity
        when :food
          if Kernel::rand > 0.5 then
            find_and_build(:farm, entity, :arable)
          else
            find_and_build(:fishing_fleet, entity)
          end
        when :power
          if Kernel::rand > 0.9 then
            find_and_build(:nuclear_plant, entity)
          elsif Kernel::rand > 0.5 then
            find_and_build(:coal_power_station, entity)
          else
            find_and_build(:oil_power_station, entity)
          end
        when :oil
          find_and_build(:well, entity)
        when :coal
          find_and_build(:coal_mine, entity)
        when :iron
          find_and_build(:iron_mine, entity)
        when :steel
          find_and_build(:foundry, entity)
        else
          puts "CAN'T SATISFY: #{commodity}"
        end
        entity.world_gen_structure(struct)

        puts "Built: #{struct}"
      end
    end

  end
end
