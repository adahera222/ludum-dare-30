require 'yogo/entity/base'

module YOGO
  module Entity
    class Country < Base

      attr_reader :statistics

      def initialize
        super

        reset_statistics
      end

      # Country have limitless budgets
      def balance
        1
      end
      def balance=(amount)
        amount
      end

      def cost_impact(detail, quantity, structure)
        # TODO: Let the Country put a price on water and air pollution
        @statistics[detail] += quantity
        0
      end

      def update(world)
        puts "#{@statistics.inspect}"
        reset_statistics
      end

    private

      def reset_statistics
        @statistics = { :air_pollution => 0.0, :water_pollution => 0.0 }
      end

    end
  end
end
