require 'yogo/structure/base'

module YOGO
  module Structure
    class CoalPowerStation < Base

      def self.name
        "Coal Power Station"
      end

      def self.description
        "5 coal -> 10 power"
      end

      def self.valid_tile?(tile)
        tile.terrain != :water
      end

      def production
        { :power => 10 * @production }
      end

      def causes
        { :air_pollution => 0.15 * @production,
          :water_pollution => 0.005 * @production
        }
      end

      def update(world)
        @running_cost = 1.0

        coal = owner.consume(:coal, 5, world)
        @production = (coal[:fulfilled].to_f / 5.0).floor.to_i
        @running_cost += coal[:price]

        super
      end

    end
  end
end
