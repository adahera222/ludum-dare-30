require 'yogo/structure/base'
require 'yogo/structure/iron_mine'

module YOGO
  module Structure
    class CoalMine < IronMine

      def self.name
        "Coal Mine"
      end

      def self.description
        "+5 coal"
      end

      def self.valid_tile?(tile)
        tile.resource == :coal
      end

      def self.produces
        { :coal => 5 }
      end

    end
  end
end
