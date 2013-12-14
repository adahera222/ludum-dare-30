require 'yogo/map'
require 'yogo/structure'

module YOGO
  class World
    attr_reader :player
    attr_accessor :ui_handler

    attr_reader :map

    def initialize
      @map = Map.new(40,40)
    end

    def update(container, delta)
    end
  end
end
