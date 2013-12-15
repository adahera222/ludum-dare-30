require 'yogo/map'
require 'yogo/market'
require 'yogo/structure/all'
require 'yogo/entity/player'
# require 'yogo/entity/corporation'

module YOGO
  class World
    attr_reader :player
    attr_accessor :ui_handler

    attr_reader :map, :market

    def initialize
      @map = Map.new(40,40)
      @market = Market.new

      @player = Entity::Player.new
      @map.entities << @player

      @turn = 0
    end

    def turn!
      @turn += 1
      puts "Turn: #{@turn}"
      @market.update(self)
      @map.update(self)

      puts @market.demand.inspect
    end
  end
end
