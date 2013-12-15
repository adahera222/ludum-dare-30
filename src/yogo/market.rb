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
      @stocks[commodity][:offers].each_with_index do |offer, idx|
        consumed = [ offer[:available], quantity ].min
        offer[:available] -= consumed
        owner.balance -= consumed * offer[:price]
        offer[:owner].balance += consumed * offer[:price]
        fulfilled += consumed
        @stocks[commodity][:available] -= consumed

        if offer[:available] == 0 then
          @stocks[commodity][:offers][idx] = nil
        end

        break if fulfilled == quantity
      end
      @stocks[commodity][:offers].compact!
      @demand[commodity] += (quantity - fulfilled)

      fulfilled
    end

    def purchase!(commodity, quantity, owner)
      purchase(commodity, quantity, owner) == quantity
    end

    def offer(commodity, quantity, price, owner)
      @stocks[commodity][:available] += quantity
      @stocks[commodity][:offers] << { :owner => owner, :price => price, :available => quantity }
      @stocks[commodity][:offers].sort_by! { |offer| offer.price }
    end

  private

    def reset_demand
      @demand = Hash.new { |hash, commodity| hash[commodity] = 0 }
    end

  end
end
