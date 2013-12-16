require 'yogo/entity/base'

module YOGO
  module Entity
    class Player < Base

      def initialize
        super

        @balance = 15.0
      end

      def name
        "Player"
      end

      def update(world)
        @stockpile.each do |commodity, data|
          stock = data[:stock]
          price = data[:cost] * 1.10   # Default 10% margin
          world.market.offer(commodity, stock, price, self)
          @stockpile[commodity][:stock] = 0
        end

        if @balance < -15.0 then
          # You are bankrupt. Game over!
          world.ui_handler.game_over!("You are bankrupt!")
        elsif @balance < 0.0 then
          world.ui_handler.critical("Your accounts are in the red. At $15m in debt, you will be put into liquidation!")
        end
      end

    end
  end
end
