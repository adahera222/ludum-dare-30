module YOGO
  class Market

    attr_reader :demand, :stocks

    def initialize
      @stocks = Hash.new { |hash, commodity| hash[commodity] = { :available => 0, :offers => [] } }
      reset_demand
    end

    def update(world)
      reset_demand
    end

    def purchase(commodity, quantity, owner)
      quantity = quantity.ceil
      fulfilled = 0
      total_price = 0
      @stocks[commodity][:offers].each_with_index do |offer, idx|
        required = quantity - fulfilled
        consumed = [ offer[:available], required ].min
        offer[:available] -= consumed
        owner.balance -= consumed * offer[:price]
        offer[:owner].balance += consumed * offer[:price]
        total_price += consumed * offer[:price]
        fulfilled += consumed
        @stocks[commodity][:available] -= consumed

        if offer[:available] == 0 then
          @stocks[commodity][:offers][idx] = nil
        end

        break if fulfilled == quantity
      end
      @stocks[commodity][:offers].compact!
      @demand[commodity] += (quantity - fulfilled)

      if fulfilled <= 0.0 then
        unit_price = 0.0
      else
        unit_price = total_price.to_f / fulfilled.to_f 
      end

      result = { :fulfilled => fulfilled, :price => total_price, :unit_price => unit_price }

      if total_price <= 0.0 then
        puts result.inspect
      end

      puts "#{owner} requested #{quantity} #{commodity}, got #{fulfilled}, at #{total_price} (#{unit_price})"

      result
    end

    def purchase!(commodity, quantity, owner)
      purchase(commodity, quantity, owner) == quantity
    end

    def offer(commodity, quantity, price, owner)
      return if quantity <= 0.0
      @stocks[commodity][:available] += quantity
      @stocks[commodity][:offers] << { :owner => owner, :price => price, :available => quantity }
      @stocks[commodity][:offers].sort_by! { |offer| offer[:price] }
      puts "#{owner} offers #{quantity} #{commodity} at #{price}"
      # puts @stocks[commodity].inspect
    end

  private

    def reset_demand
      @demand = Hash.new { |hash, commodity| hash[commodity] = 0 }
    end

  end
end
