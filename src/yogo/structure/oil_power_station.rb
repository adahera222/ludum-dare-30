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

      def consumes
        { :oil => 5 }
      end

      def causes
        { :air_pollution => 0.1 * @production,
          :water_pollution => 0.010 * @production
        }
      end

    end
  end
end
