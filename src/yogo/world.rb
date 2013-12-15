require 'yogo/map'
require 'yogo/structure/all'

module YOGO
  class World
    attr_reader :player
    attr_accessor :ui_handler

    attr_reader :map

    def initialize
      @map = Map.new(40,40)
      @turn = 0
    end

    def turn!
      @turn += 1
      puts "Turn: #{@turn}"
      @map.update!
    end
  end
end
