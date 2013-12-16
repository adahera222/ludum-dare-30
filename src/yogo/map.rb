require 'yogo/tile'
require 'yogo/entity/country'

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

    def world_gen_update(world)
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

    def update(world)
      @entities.each do |entity|
        entity.update(world)
      end
      @tiles.each do |pos, cell|
        cell.update(world)
      end
    end

  private

    def random!
      generate_tectonic_plates
      generate_countries_and_capitals
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
      (width/4).times do
        pos = nil
        dist = 0.0

        while pos.nil? || pos.terrain == :water || !pos.resource.nil? || !pos.structure.nil? || dist < min_dist do
          pos = self[[ Kernel::rand(@maxx), Kernel::rand(@maxy) ]]
          if @capitals.length > 0 then
            dist = @capitals.collect { |other| ((other.tile.x - pos.x) ** 2) + ((other.tile.y - pos.y) ** 2) }.min
          else
            dist = 9999.00
          end
        end

        country = Entity::Country.new
        country.color = COUNTRY_COLOURS[idx]
        @entities << country

        city = Structure.create(:city, pos)
        city.owner = country
        city.population = 1.0 + Kernel::rand(5.0)
        city.name = "City #{idx}"
        pos[:structure] = city
        pos[:state] = country

        @capitals << city

        idx += 1
      end

      @unmapped = (width * height) - @capitals.length
      # @unmapped = 0
    end

  end
end
