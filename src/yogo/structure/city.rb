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
        growth_rate += 0.03 if @owner.consume!(:food, @population.ceil, world)
        growth_rate -= 0.03 unless @owner.consume!(:power, (@population * 2.0).ceil, world)
        growth_rate += 0.015 if @owner.consume!(:timber, @population.ceil, world)
        growth_rate += 0.015 if @owner.consume!(:steel, @population.ceil, world)
        growth_rate -= 0.015 unless @owner.consume!(:oil, (@population * 2.0).ceil, world)

        @population *= growth_rate
      end

    end
  end
end
