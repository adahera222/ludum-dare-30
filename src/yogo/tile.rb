module YOGO
  class Tile

    attr_reader :pos

    def initialize(pos)
      @pos = pos
      @data = {}
    end

    def x
      @pos[0]
    end

    def y
      @pos[1]
    end

  end
end
