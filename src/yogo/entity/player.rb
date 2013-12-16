require 'yogo/entity/base'

module YOGO
  module Entity
    class Player < Base

      def initialize
        super

        @balance = 15.0
      end

      def update(world)
        @stockpile.each do |commodity, data|
          stock = data[:stock]
          price = data[:cost] * 1.10   # Default 10% margin
          world.market.offer(commodity, stock, price, self)
          @stockpile[commodity][:stock] = 0
        end
        puts "BALANCE: #{@balance}"
      end

    end
  end
end
