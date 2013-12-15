require 'yogo/entity/base'

module YOGO
  module Entity
    class Player < Base

      def initialize
        super

        @balance = 0
      end

      def update(world)
        @stockpile.each do |commodity, stock|
          world.market.offer(commodity, stock, 10, self)
          @stockpile[commodity] = 0
        end
        puts "BALANCE: #{@balance}"
      end

    end
  end
end
