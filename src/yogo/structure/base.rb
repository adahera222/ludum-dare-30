module YOGO
  module Structure

    def self.name(type)
      STRUCTURES[type].name
    end

    def self.description(type)
      STRUCTURES[type].description
    end

    def self.price(type)
      STRUCTURES[type].setup_cost
    end

    def self.running_cost(type)
      STRUCTURES[type].running_cost
    end

    def self.create(type, pos)
      klass = STRUCTURES[type]
      klass.new(type, pos)
    end

    class Base

      attr_reader :type, :tile, :notes, :icons
      attr_reader :owner

      attr_reader :income, :profitability

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

      def consumes
        {}
      end

      def causes
        {}
      end

      def update(world)
        @production = 1.0
        @notes = []
        @icons = []
        @income = 0.0

        if self.class.respond_to?(:running_cost) then
          @running_cost = self.class.running_cost.to_f
        else
          @running_cost = 0.0
        end

        @owner.balance -= @running_cost

        do_production(world) if self.respond_to?(:do_production)

        causes.each do |detail, effect|
          @tile[detail] += effect
          @running_cost += @tile.state.cost_impact(detail, effect, self)
        end

        production.each do |commodity, quantity|
          @owner.store(commodity, quantity, @running_cost / quantity) unless quantity <= 0
          @income += quantity * world.market.price(commodity)
        end

        @profitability = @income / @running_cost
      end

    end
  end
end
