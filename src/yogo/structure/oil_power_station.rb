require 'yogo/structure/base'
require 'yogo/structure/coal_power_station'

module YOGO
  module Structure
    class OilPowerStation < CoalPowerStation

      def self.name
        "Oil Power Station"
      end

      def self.description
        "5 oil -> 10 power"
      end

      def causes
        { :air_pollution => 0.1 * @production,
          :water_pollution => 0.010 * @production
        }
      end

      def update(world)
        oil = owner.consume(:oil, 5, world)
        @production = (oil[:fulfilled].to_f / 5.0).floor.to_i
        @running_cost += oil[:price]

        super
      end

    end
  end
end
