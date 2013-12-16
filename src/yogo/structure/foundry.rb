require 'yogo/structure/base'
require 'yogo/structure/coal_power_station'
module YOGO
  module Structure
    class Foundry < Base

      def self.name
        "Steel Foundry"
      end

      def self.description
        "5 coal, iron, power -> 5 steel"
      end

      def self.valid_tile?(tile)
        !([ :water, :mountains ].include?(tile.terrain))
      end

      def self.setup_cost
        26
      end

      def self.running_cost
        3.0
      end

      def self.produces
        { :steel => 5 }
      end

      def consumes
        { :coal => 5, :iron => 5, :power => 5 }
      end

      def production
        { :steel => 5 * @production }
      end

      def causes
        { :air_pollution => 0.2 * @production,
          :water_pollution => 0.010 * @production
        }
      end

      # TODO: Extract to a Concern along with CoalPowerStation
      def do_production(world)
        cs = self.consumes
        cs.each do |commodity, quantity|
          item = owner.consume(commodity, quantity, world)
          @production *= (item[:fulfilled].to_f / quantity.to_f).floor.to_i
          @running_cost += item[:price]
        end
      end

    end
  end
end
