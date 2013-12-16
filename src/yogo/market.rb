module YOGO
  class Market

    attr_reader :demand, :stocks

    def initialize
      @stocks = Hash.new { |hash, commodity| hash[commodity] = { :available => 0, :price => 0.0 } }
      reset_demand
    end

    def update(world)
      reset_demand
    end

    def purchase(commodity, quantity, owner)
      quantity = quantity.ceil
      data = @stocks[commodity]

      puts "#{owner} requested #{quantity} #{commodity}"

      fulfilled = [ data[:available], quantity ].min
      data[:available] -= fulfilled
      data[:price] *= (1.0 + (quantity * 0.002))
      total_price = fulfilled * data[:price]

      @demand[commodity] += quantity - fulfilled

      owner.balance -= total_price
      puts "    => got #{fulfilled}, at #{data[:price]} = #{total_price} (#{data[:available]} in stock)"
      result = { :fulfilled => fulfilled, :price => total_price, :unit_price => data[:price] }
      result
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
      @demand = Hash.new { |hash, commodity| hash[commodity] = 0 }
    end

  end
end
