require 'yogo/entity/base'

module YOGO
  module Entity
    class Country < Base

      attr_reader :statistics

      def initialize
        super

        reset_statistics
        reset_lobby_values

        @taxes = { :air_pollution => 0.0, :water_pollution => 0.0 }
        consider_regulations
      end

      # Country have limitless budgets
      def balance
        1
      end
      def balance=(amount)
        amount
      end

      def cost_impact(detail, quantity, structure)
        # Let the Country put a price on water and air pollution
        @statistics[detail] += quantity
        @taxes[detail] * quantity
      end

      def risk_assessment(detail, quantity, structure)
        @statistics[detail] += quantity
      end

      def update(world)
        consider_regulations
        puts "#{@statistics.inspect}"
        puts "#{@lobby.inspect}"
        puts "#{@taxes.inspect}"
        reset_statistics
      end

    private

      def reset_statistics
        @statistics = { :air_pollution => 0.0, :water_pollution => 0.0, :inundation => 0.0 }
      end

      def reset_lobby_values
        @lobby = {
          :air_pollution => { :accumulated => 0.0, :for => 0.0, :against => 0.0, :sway => 0.0 },
          :water_pollution => { :accumulated => 0.0, :for => 0.0, :against => 0.0, :sway => 0.0 }
        }
      end

      def consider_regulations
        inundation_panic = @statistics[:inundation] / 0.25

        [ :air_pollution, :water_pollution ].each do |detail|
          @lobby[detail][:accumulated] += @lobby[detail][:sway]
          if @lobby[detail][:accumulated].abs >= 1.0 then
            alter = (@lobby[detail][:accumulated] * inundation_panic * 0.1)
            @taxes[detail] += alter
            @taxes[detail] = 0.0 if @taxes[detail] < 0.0
          end
        end
      end

    end
  end
end
