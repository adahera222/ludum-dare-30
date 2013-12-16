module YOGO
  module Entity

    class Base
      attr_accessor :balance
      attr_accessor :color
      attr_accessor :structures
      attr_accessor :name

      def initialize
        @balance = 0
        @stockpile = Hash.new { |hash, commodity| hash[commodity] = { :stock => 0, :cost => 0 } }
        @structures = []
      end

      def to_s
        "#<#{self.class.name} #{name.inspect} #{sprintf('$%.2f', @balance)}>"
      end
      alias :inspect :to_s

      def running?
        @running
      end

      def update(world)
        # NOOP
      end

      def add_structure(structure)
        @structures << structure
        @structures = @structures.compact.uniq
      end

      def remove_structure(structure)
        @structures -= [ structure ]
        @structures = @structures.compact.uniq
      end

      def store(commodity, quantity, unit_cost)
        cost_of_stockpile = @stockpile[commodity][:cost] * @stockpile[commodity][:stock]
        @stockpile[commodity][:stock] += quantity
        cost_of_stockpile += quantity * unit_cost
        @stockpile[commodity][:cost] = cost_of_stockpile / @stockpile[commodity][:stock]
        puts "Storing #{quantity} #{commodity} at unit cost of #{unit_cost}"
        true
      end

      def consume(commodity, quantity, world)
        from_stockpile = [ quantity, @stockpile[commodity][:stock] ].min
        required = quantity - from_stockpile

        fulfilled = from_stockpile
        total_cost = @stockpile[commodity][:cost] * from_stockpile
        @stockpile[commodity][:stock] -= from_stockpile

        if required > 0 then
          purchase = world.market.purchase(commodity, required, self)
          fulfilled += purchase[:fulfilled]
          total_cost += purchase[:price]
        end

        { :fulfilled => fulfilled, :price => total_cost, :unit_price => total_cost.to_f / fulfilled.to_f }
      end

      def consume!(commodity, quantity, world)
        consume(commodity, quantity, world)[:fulfilled] == quantity
      end
    end
  end
end
