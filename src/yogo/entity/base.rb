module YOGO
  module Entity
    class Base

      attr_accessor :balance
      attr_accessor :stockpile

      def initialize
        @balance = 0
        @stockpile = Hash.new { |hash, commodity| hash[commodity] = 0 }
        @stockpile = Hash.new { |hash, commodity| hash[commodity] = 0 }
      end

      def update(world)
        # NOOP
      end

    end
  end
end
