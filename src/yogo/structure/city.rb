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

      def self.name
        "City"
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

      def causes
        { :air_pollution => 0.02 * @population,
          :water_pollution => 0.01 * @population
        }
      end

      def update(world)
        super

        growth_rate = 1.0

        # Growth rates at ~3-6% per year
        if @owner.consume!(:food, @population.ceil, world)
          growth_rate += 0.03
        else
          world.ui_handler.location_alert("#{self.name} are starving!", @tile)
          @notes << 'Starvation'
          @icons << :starvation
        end

        unless @owner.consume!(:power, (@population * 2.0).ceil, world)
          growth_rate -= 0.03
          world.ui_handler.location_alert("#{self.name} has now power!", @tile)
          @notes << 'No Power'
          @icons << :no_power
        end

        if @owner.consume!(:steel, @population.ceil, world)
          growth_rate += 0.015
        else
          world.ui_handler.location_alert("#{self.name} can't grow due to a lack of steel", @tile)
          @notes << 'No Steel'
          @icons << :no_steel
        end

        if tile.air_pollution > 0.75 then
          growth_rate -= 0.05
          world.ui_handler.location_alert("#{self.name} citizens are dying due to toxic air pollution", @tile)
        elsif tile.air_pollution > 0.5 then
          growth_rate -= 0.02
          world.ui_handler.location_alert("#{self.name} citizens are having major health issues due to air pollution", @tile)
        elsif tile.air_pollution > 0.25 then
          growth_rate -= 0.01
          world.ui_handler.location_alert("#{self.name} citizens are having health issues due to air pollution", @tile)
        end

        @population *= growth_rate

        @tile.state.risk_assessment(:inundation, @tile.inundation, self)
      end

    end
  end
end
