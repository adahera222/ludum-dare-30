module YOGO
  class Tile

    attr_reader :pos

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

  end
end
