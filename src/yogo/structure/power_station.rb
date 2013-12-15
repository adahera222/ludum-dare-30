require 'yogo/structure/base'

module YOGO
  module Structure
    class PowerStation < Base

      def production
        { :power => 10 * @production }
      end

      def causes
        { :air_pollution => 0.1 * @production,
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
