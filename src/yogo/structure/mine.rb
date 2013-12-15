require 'yogo/structure/base'

module YOGO
  module Structure
    class Mine < Base

      def production
        { @tile[:resource] => 5 }
      end

      def update(world)
        # TODO: Give production into the Owner's stockpile
        # Create pollution on the tile we are on
        @tile[:water_pollution] += 0.1
        @tile[:air_pollution] += 0.2
      end

    end
  end
end
