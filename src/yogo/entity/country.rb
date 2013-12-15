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
        consider_regulations(nil)
      end

      def name
        "Unknownistan"
      end

      def air_pollution_tax
        @taxes[:air_pollution]
      end

      def water_pollution_tax
        @taxes[:water_pollution]
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

      def lobby(detail, amount, entity)
        if amount < 0.0 then
          @lobby[detail][:against] += amount
        else
          @lobby[detail][:for] += amount
        end
        @lobby[detail][:sway] = (@lobby[detail][:against] + @lobby[detail][:for]) / population * 0.1
      end

      def population
        @structures.inject(0.0) { |sum, structure| sum + (structure.respond_to?(:population) ? structure.population : 0.0) }
      end

      def update(world)
        consider_regulations(world)
        puts "STATS: #{@statistics.inspect}"
        puts "LOBBY: #{@lobby.inspect}"
        puts "TAX: #{@taxes.inspect}"
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

      def consider_regulations(world)
        inundation_panic = @statistics[:inundation] / 0.25

        [ :air_pollution, :water_pollution ].each do |detail|
          @lobby[detail][:accumulated] += @lobby[detail][:sway]
          @lobby[detail][:accumulated] += inundation_panic * 0.1
          if @lobby[detail][:accumulated].abs >= 1.0 then
            alter = (@lobby[detail][:accumulated] * (inundation_panic + 0.01))
            @taxes[detail] += alter
            @taxes[detail] = 0.0 if @taxes[detail] < 0.0
            @lobby[detail][:accumulated] = 0.0

            world.ui_handler.notice("#{self.name} has changed their #{detail} tax rate to #{sprintf('$%.2f per 1 unit', @taxes[detail])}") if world
          end
        end
      end

    end
  end
end
