require 'yogo/structure/base'

module YOGO
  module Structure
    class WindFarm < Base

      def self.name
        "Wind Farm"
      end

      def self.description
        "+5 power"
      end

      def self.valid_tile?(tile)
        tile.terrain != :water
      end

      def self.setup_cost
        8
      end

      def self.running_cost
        4
      end

      def production
        { :power => 5 }
      end

      def causes
        {}
      end

    end
  end
end
