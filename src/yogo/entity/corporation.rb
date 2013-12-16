require 'yogo/entity/base'

module YOGO
  module Entity
    class Corporation < Base

      attr_accessor :name

      def initialize
        super

        @balance = 15.0
        @running = true
      end

      def update(world)
        next unless @running
        if @balance < -15.0 then

          @structures.each do |structure|
            structure.tile[:structure] = nil
          end
          @structures = []

          @running = false
          world.ui_helper.notice("#{name} has gone out of business!")
        end
      end

    end
  end
end
