require 'yogo/structure/base'

module YOGO
  module Structure
    class City < Base

      attr_accessor :population
      attr_writer :name

      def initialize(type, tile)
        super

        @population = 1.0
      end

      def name
        # "#{@name} [#{citizens}]"
        "#{@name} [#{sprintf('%.2f', @population)}]"
      end

      def production
        {}
      end

      def citizens
        @population.floor
      end

      def update(world)
        super

        # Create pollution on the tile we are on
        @tile[:water_pollution] += 0.01 * @population
        @tile[:air_pollution] += 0.02 * @population

        growth_rate = 1.0

        # Growth rates at ~3-6% per year
        growth_rate += 0.03 if world.market.purchase!(:food, @population.ceil, @owner)
        growth_rate -= 0.03 unless world.market.purchase!(:power, (@population * 2.0).ceil, @owner)
        growth_rate += 0.015 if world.market.purchase!(:timber, @population.ceil, @owner)
        growth_rate += 0.015 if world.market.purchase!(:steel, @population.ceil, @owner)
        growth_rate -= 0.015 unless world.market.purchase!(:oil, (@population * 2.0).ceil, @owner)

        @population *= growth_rate
      end

    end
  end
end
