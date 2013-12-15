require 'yogo/structure/base'

module YOGO
  module Structure
    class Mine < Base

      def production
        { @tile.resource => 5 }
      end

      def update(world)
        if @tile.resource == :oil then
          @running_cost = 2.0
        else
          @running_cost = 10.0
        end

        super

        # Create pollution on the tile we are on
        @tile[:water_pollution] += 0.1
        @tile[:air_pollution] += 0.01
      end

    end
  end
end
