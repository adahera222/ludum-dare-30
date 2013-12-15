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

    def generating?
      @map.unmapped > 0
    end

    def update(game, container)
      if generating? then
        @map.world_gen_update(self)
      end
    end

    def turn!
      @turn += 1
      puts "---------"
      puts "Turn: #{@turn}"
      @market.update(self)
      @map.update(self)

      puts @market.demand.inspect

      @air_pollution = 0.0
      @water_pollution = 0.0

      @map.entities.each do |entity|
        next unless entity.is_a?(Entity::Country)

        @air_pollution += entity.statistics[:air_pollution]
        @water_pollution += entity.statistics[:water_pollution]
      end

      puts "WORLD: AIR: #{@air_pollution} WATER: #{@water_pollution} RATE: #{warming_rate}"
    end

    def warming_rate
      if @air_pollution.nil? then
        0.0
      else
        -0.5 + (@air_pollution / ((@map.width * @map.height) / 1500.0))
      end
    end
  end
end
