require 'yogo/tile'

module YOGO
  class Map

    def initialize(width, height)
      @maxx = width - 1
      @maxy = height - 1

      @cells = Hash.new { |hash, pos| hash[pos] = Tile.new(pos) }

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
      @cells[pos]
    end

    def in_range?(pos)
      x,y = pos
      (x >= 0 && x <= @maxx) && (y >= 0 && y <= @maxy)
    end

  private

    def random!
      generate_tectonic_plates

      # TODO: Scatter resources randomly on the map
      # TODO: Decide sea level to give ~70% water
      # TODO: Seed rainfall based upon evaporation, expands to hit
      #       mountains
      # TODO: Rainfall on regions will produce rivers flowing ever lower
    end

    # TODO: Generate random plates and give them a height
    # TODO: Where two plates overlap, decide if it's a +1 or a -1
    def generate_tectonic_plates
      10.times do
        candidates = { }

        radius = (width / 4) * (1.0 + Kernel::rand)
        pos = [ Kernel::rand(@maxx), Kernel::rand(@maxy) ]
        cx,cy = pos

        tiles = { pos => true }

        1.upto(radius) do |r|
          (cx-r).upto(cx+r) do |x|
            (cy-r).upto(cy+r) do |y|
              pos = [x,y]
              next if tiles[pos]
              next unless in_range?(pos)

              tiles[pos] = true

              self[pos][:height] ||= 0
              self[pos][:height] += 1
            end
          end
        end
      end
    end

  end
end
