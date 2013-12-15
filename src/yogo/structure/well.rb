require 'yogo/structure/base'

module YOGO
  module Structure
    class Well < Base

      def self.name
        "Well"
      end

      def self.description
        "+5 oil"
      end

      def self.valid_tile?(tile)
        tile.resource == :oil
      end

      def production
        { :oil => 5 }
      end

      def causes
        { :air_pollution => 0.01 * @production,
          :water_pollution => 0.2 * @production
        }
      end

      def update(world)
        @running_cost = 3.0

        super
      end

    end
  end
end
