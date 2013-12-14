require 'yogo/tile'

module YOGO
  class Map

    def initialize(width, height)
      @maxx = width - 1
      @maxy = height - 1

      @cells = Hash.new { |hash, pos| hash[pos] = Tile.new(pos) }
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

  end
end
