require 'yogo/structure/base'

module YOGO
  module Structure
    class Farm < Base

      def production
        { :food => 3 }
      end

      def update(world)
        super

        # Trees, stuff like that to absorb the pollution
        @tile[:air_pollution] -= 0.005

        if @tile.resource == :arable then
          # Arable land needs little fertilizer, so has a lower water
          # pollution impact
          @tile[:water_pollution] += 0.005
        else
          @tile[:water_pollution] += 0.012
        end
      end

    end
  end
end
