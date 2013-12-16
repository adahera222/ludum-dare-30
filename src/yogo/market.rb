module YOGO
  class Market

    STOCK_SEED_PRICES = {
      :iron => 2,
      :coal => 2,
      :oil => 3,
      :food => 0.4,
      :steel => 5,
      :power => 0.4
    }


    attr_reader :stocks

    def initialize
      @stocks = Hash.new { |hash, commodity| hash[commodity] = { :available => 0, :price => STOCK_SEED_PRICES[commodity].to_f } }
      reset_demand
    end

    def update(world)
      @last_stocks = @stocks.dup
      reset_demand
    end

    def demand
      @last_demand || @demand
    end

    def available(commodity)
      @last_stocks[commodity][:available]
    end

    def live_demand
      @demand
    end

    def purchase(commodity, quantity, owner)
      quantity = quantity.ceil
      data = @stocks[commodity]

      puts "#{owner} requested #{quantity} #{commodity}"

      fulfilled = [ data[:available], quantity ].min
      data[:available] -= fulfilled
      data[:price] *= (1.0 + (quantity * 0.002))
      total_price = fulfilled * data[:price]

      @demand[commodity] += quantity

      owner.balance -= total_price
      puts "    => got #{fulfilled}, at #{data[:price]} = #{total_price} (#{data[:available]} in stock)"
      result = { :fulfilled => fulfilled, :price => total_price, :unit_price => data[:price] }
      result
    end

    def price(commodity)
      @stocks[commodity][:price]
    end

    def purchase!(commodity, quantity, owner)
      purchase(commodity, quantity, owner) == quantity
    end

    def offer(commodity, quantity, price, owner)
      return if quantity <= 0.0
      puts "#{owner} offers #{quantity} #{commodity} at #{price}"

      data = @stocks[commodity]

      total = data[:available] * data[:price]
      data[:available] += quantity
      data[:price] = ((total + (quantity * price)) / data[:available]) * (1.0 - (quantity * 0.002))

      @demand[commodity] -= quantity

      total_sale = data[:price] * quantity
      puts "     => sold #{quantity} #{commodity} at #{data[:price]} = #{total_sale} (#{data[:available]} in stock)"
      owner.balance += total_sale
    end

  private

    def reset_demand
      @last_demand = @demand.dup if @demand
      @demand = Hash.new { |hash, commodity| hash[commodity] = 0 }
    end

  end
end
