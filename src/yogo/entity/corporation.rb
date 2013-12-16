require 'yogo/entity/base'

module YOGO
  module Entity
    class Corporation < Base

      def initialize
        super

        @balance = 100.0
        @running = true
        @minimum_calcs = nil

        @demand_triggers = {}
        @decommission_triggers = {}
        @purchase_triggers = {}
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

        decide_action(world)

        if @balance < -100.0 then
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
          @stockpile[c][:stock] += q * 2
          @stockpile[c][:cost] = Market::STOCK_SEED_PRICES[c]
        end
        structure.production.each do |c, q|
          @stockpile[c][:stock] += q
          @stockpile[c][:cost] = Market::STOCK_SEED_PRICES[c]
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

      def decide_action(world)
        @structures.each do |structure|
          # Decide to repoen a structure
          if !structure.running? then
            potential_income = 0.0
            potential_costs = structure.class.running_cost
            structure.production.each do |commodity, quantity|
              potential_income += world.market.price(commodity) * quantity
            end
            structure.consumes.each do |commodity, quantity|
              potential_costs += world.market.price(commodity) * quantity
            end
            profitability = (potential_income / potential_costs)
            puts "#{self.name}: DECOM: #{structure.inspect} pot prof: #{profitability}"
            if profitability > 1.0 then
              @decommission_triggers[structure] = 0.0
              @purchase_triggers[structure.type] = -100.0
              structure.reopen!
              world.ui_handler.location_alert("#{self.name} has reopened #{structure.name}", structure.tile)
            end
          end

          next if structure.profitability.nil?
          # Decide to shut down a structure
          @decommission_triggers[structure] ||= 0.0
          @decommission_triggers[structure] += (structure.profitability.to_f / 6.0)
          @decommission_triggers[structure] = 0.5 if @decommission_triggers[structure] > 0.5
          if @decommission_triggers[structure] <= -0.75 then
            # Shut it down for the moment
            structure.shutdown!
            world.ui_handler.location_alert("#{self.name} has temporarily closed #{structure.name}", structure.tile)
            @purchase_triggers[structure.type] = -100.0
          end

          if @decommission_triggers[structure] <= -1.5 then
            # This is beyond a joke - destroy it entirely
            world.map.destroy_structure(structure)
            world.ui_handler.location_alert("#{self.name} has fully decommissioned a #{structure.name}", structure.tile)
            @purchase_triggers[structure.type] = -100.0
          end
        end
        puts "#{self.name}: DECOM: #{@decommission_triggers.inspect}"

        # TODO: Decide to build a structure
        Structure::STRUCTURES.each do |type, klass|
          next unless klass.respond_to?(:running_cost)

          potential_income = 0.0
          potential_costs = klass.running_cost.to_f
          klass.produces.each do |c,q|
            potential_income += world.market.price(c) * 0.9 * ([ world.market.demand[c], q ].min / (world.market.available(c) + 1.0))
          end
          profit = potential_income / potential_costs
          @purchase_triggers[type] ||= 0.0
          @purchase_triggers[type] += (profit / (klass.setup_cost.to_f / 4.0)) * Kernel::rand
          @purchase_triggers[type] = -5.0 if @purchase_triggers[type] < -5.0
        end
        puts "#{self.name}: NEW: #{@purchase_triggers.inspect}"
        Structure::STRUCTURES.to_a.reject { |d| !(d[1].respond_to?(:setup_cost)) }.sort_by { |d| d[1].setup_cost }.reverse.each do |d|
          type = d[0]
          if @purchase_triggers[type] > 0.5 then

            # BUILD IT
            if @balance >= d[1].setup_cost + (@structures.count * 10.0) then
              s = world.map.find_and_build(d[0], self)
              if s then
                @balance -= d[1].setup_cost
                world.ui_handler.location_alert("#{self.name} has just built a new #{s.name}", s.tile)
                @purchase_triggers[d[0]] = -5.0
                @minimum_calcs = nil
                break
              end
            end
          end

        end


        # TODO: Decide to lobby to reduce costs
        # TODO: Decide to lobby combatively
      end

    end
  end
end
