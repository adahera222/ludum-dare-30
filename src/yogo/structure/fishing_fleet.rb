require 'yogo/structure/base'

module YOGO
  module Structure
    class FishingFleet < Base

      def self.name
        "Fishing Fleet"
      end

      def self.description
        "+3 food"
      end

      def self.valid_tile?(tile)
        tile.terrain == :water
      end

      def self.setup_cost
        1
      end

      def self.running_cost
        1.5
      end

      def self.produces
        { :food => 3 }
      end

      def causes
        c = { :air_pollution => 0.005 }
        c[:water_pollution] = 0.010
        c
      end

    end
  end
end
