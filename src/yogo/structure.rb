module YOGO
  class Structure

    NAMES = {
      :mine => 'Mine',
      :factory => 'Factory',
      :power_station => 'Power Station',
      :well => 'Well'
    }

    attr_reader :type, :pos
    attr_accessor :owner

    def initialize(type, pos)
      @type = type
      @pos = pos

      @owner = nil
    end

    def self.name(type)
      NAMES[type]
    end

    def name
      NAMES[@type]
    end

  end
end
