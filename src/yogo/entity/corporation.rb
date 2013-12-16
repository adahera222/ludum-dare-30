require 'yogo/entity/base'

module YOGO
  module Entity
    class Corporation < Base

      STOCK_SEED_PRICES = {
        :iron => 4,
        :coal => 4,
        :oil => 0.8,
        :food => 0.8,
        :steel => 10,
        :power => 0.8
      }

      def initialize
        super

        @balance = 100.0
        @running = true
        @minimum_calcs = nil
      end

      def margin(commodity)
        0.1
      end

      def minimum(commodity)
        prepare_minimum_calcs
        @minimum_calcs[commodity] || 0.0
      end

      def update(world)
        return unless @running

        @stockpile.each do |commodity, data|
          # Stockpile 3 months worth of input for industries, but sell
          # any excess
          stock = [ 0, data[:stock] - minimum(commodity) ].max
          price = data[:cost] * (1.0 + margin(commodity))   # Default 10% margin
          world.market.offer(commodity, stock, price, self)
          @stockpile[commodity][:stock] -= stock
        end

        if @balance < -50.0 then
          @structures.each do |structure|
            structure.tile[:structure] = nil
          end
          @structures = []

          @running = false
          world.ui_handler.notice("#{name} has gone out of business!")
        end
      end

      def world_gen_structure(structure)
        structure.consumes.each do |c, q|
          @stockpile[c][:stock] += q * 3
          @stockpile[c][:cost] = STOCK_SEED_PRICES[c]
        end
        structure.production.each do |c, q|
          @stockpile[c][:stock] += q
          @stockpile[c][:cost] = STOCK_SEED_PRICES[c]
        end
      end

    private

      def prepare_minimum_calcs
        if @minimum_calcs.nil? then
          @minimum_calcs = {}
          @structures.each do |structure|
            structure.consumes.each do |commodity, quantity|
              @minimum_calcs[commodity] = (@minimum_calcs[commodity] || 0) + (quantity * 3)
            end
          end
          puts "#{self}: Holding #{@minimum_calcs.inspect}"
          puts "       : Stocked #{@stockpile.inspect}"
        end
      end

    end
  end
end
