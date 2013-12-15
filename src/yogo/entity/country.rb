require 'yogo/entity/base'

module YOGO
  module Entity
    class Country < Base

      def initialize
        super
      end

      # Country have limitless budgets
      def balance
        1
      end
      def balance=(amount)
        amount
      end

    end
  end
end
