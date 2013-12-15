module YOGO
  module Structure

    def self.name(type)
      STRUCTURES[type].name
    end

    def self.description(type)
      STRUCTURES[type].description
    end

    def self.create(type, pos)
      klass = STRUCTURES[type]
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
        Structure.name(@type)
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
