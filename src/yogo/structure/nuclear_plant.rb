require 'yogo/structure/base'

module YOGO
  module Structure
    class NuclearPlant < Base

      def self.name
        "Nuclear Plant"
      end

      def self.description
        "+13 power"
      end

      def self.valid_tile?(tile)
        tile.terrain != :water
      end

      def self.setup_cost
        25
      end

      def self.running_cost
        5
      end

      def production
        { :power => 13 }
      end

      def causes
        c = { :air_pollution => 0.04 }
        c[:water_pollution] = 0.04
        c
      end

    end
  end
end
