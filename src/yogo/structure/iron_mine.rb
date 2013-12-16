require 'yogo/structure/base'

module YOGO
  module Structure
    class IronMine < Base

      def self.name
        "Iron Mine"
      end

      def self.description
        "+5 iron"
      end

      def self.setup_cost
        33
      end

      def self.running_cost
        10
      end

      def self.valid_tile?(tile)
        tile.resource == :iron
      end

      def self.produces
        { :iron => 5 }
      end

      def causes
        { :air_pollution => 0.01 * @production,
          :water_pollution => 0.1 * @production
        }
      end

    end
  end
end
