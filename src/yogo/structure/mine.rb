require 'yogo/structure/base'

module YOGO
  module Structure
    class Mine < Base

      def production
        { @tile.resource => 5 }
      end

      def causes
        { :air_pollution => 0.01 * @production,
          :water_pollution => 0.1 * @production
        }
      end

      def update(world)
        if @tile.resource == :oil then
          @running_cost = 2.0
        else
          @running_cost = 10.0
        end

        super
      end

    end
  end
end
