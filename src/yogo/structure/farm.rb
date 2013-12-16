require 'yogo/structure/base'

module YOGO
  module Structure
    class Farm < Base

      def self.name
        "Farm"
      end

      def self.description
        "+3 food"
      end

      def self.valid_tile?(tile)
        tile.terrain != :water
      end

      def self.setup_cost
        2
      end

      def self.running_cost
        1
      end

      def self.produces
        { :food => 3 }
      end

      def causes
        c = { :air_pollution => -0.005 }
        if @tile.resource == :arable then
          # Arable land needs little fertilizer, so has a lower water
          # pollution impact
          c[:water_pollution] = 0.005
        else
          c[:water_pollution] = 0.012
        end
        c
      end

    end
  end
end
