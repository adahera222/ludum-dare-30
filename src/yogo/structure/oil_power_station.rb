require 'yogo/structure/base'

module YOGO
  module Structure
    class OilPowerStation < Base

      def self.name
        "Oil Power Station"
      end

      def self.description
        "5 oil -> 10 power"
      end

      def self.valid_tile?(tile)
        tile.terrain != :water
      end

      def production
        { :power => 10 * @production }
      end

      def causes
        { :air_pollution => 0.1 * @production,
          :water_pollution => 0.010 * @production
        }
      end

      def update(world)
        @running_cost = 1.0

        oil = owner.consume(:oil, 5, world)
        @production = (oil[:fulfilled].to_f / 5.0).floor.to_i
        @running_cost += oil[:price]

        super
      end

    end
  end
end
