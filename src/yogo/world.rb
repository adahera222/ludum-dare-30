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
      @map = Map.new(50,50)
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
      @ui_handler.turn!
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
      if warming_rate > 0.75 then
        @ui_handler.notice("Scientists report the polar icecaps are melting rapidly")
      elsif warming_rate > 0.5 then
        @ui_handler.notice("Scientists report the polar icecaps are melting")
      elsif warming_rate > 0.25 then
        @ui_handler.notice("Scientists report the climate is starting to change heavily")
      elsif warming_rate > 0.05 then
        @ui_handler.notice("Scientists are concerned about climate change")
      elsif warming_rate < 0.00 then
        @ui_handler.notice("Scientists are pleased that climate change appears to be reversing")
      end
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
