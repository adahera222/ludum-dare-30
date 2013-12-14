require 'yogo/map'

module YOGO
  class World
    attr_reader :player
    attr_accessor :ui_handler

    attr_reader :map

    def initialize
      @map = Map.new(10,10)
    end

    def update(container, delta)
    end
  end
end
