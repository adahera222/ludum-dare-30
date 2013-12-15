module YOGO
  module Structure

    NAMES = {
      :mine => 'Mine',
      :factory => 'Factory',
      :power_station => 'Power Station',
      :well => 'Well',
      :farm => 'Farm'
    }

    def self.name(type)
      NAMES[type]
    end

    def self.create(type, pos)
      klass = case type
              when :mine, :well
                Mine
              when :city
                City
              when :farm
                Farm
              when :power_station
                PowerStation
              # when :nuclear_plant
              #   NuclearPlant
              # when :wind_farm
              #   WindFarm
              # when :solar_farm
              #   SolarFarm
              # when :factory
              #   Factory
              end

      klass.new(type, pos)
    end

    class Base

      attr_reader :type, :tile, :notes, :icons
      attr_reader :owner

      def initialize(type, tile)
        @type = type
        @tile = tile

        @owner = nil

        @production = 1.0
        @running_cost = 0

        @notes = []
        @icons = []
      end

      def name
        NAMES[@type]
      end

      def owner=(owner)
        @owner = owner
        @owner.add_structure(self)
      end

      def production
        {}
      end

      def causes
        {}
      end

      def update(world)
        @notes = []
        @icons = []

        causes.each do |detail, effect|
          @tile[detail] += effect
          @running_cost += @tile.state.cost_impact(detail, effect, self)
        end

        @owner.balance -= @running_cost

        production.each do |commodity, quantity|
          @owner.store(commodity, quantity, @running_cost / quantity) unless quantity <= 0
        end

      end

      # def production
      #   case @type
      #   when :power_station
      #     { :power => 10 }
      #   when :nuclear_plant
      #     { :power => 13 }
      #   when :wind_farm
      #     { :power => 8 }
      #   when :solar_farm
      #     { :power => 5 }
      #   when :factory
      #     { :production => 10 }
      #   end
      # end

    end
  end
end
