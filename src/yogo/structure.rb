module YOGO
  class Structure

    NAMES = {
      :mine => 'Mine',
      :factory => 'Factory',
      :power_station => 'Power Station',
      :well => 'Well',
      :farm => 'Farm'
    }

    attr_reader :type, :tile
    attr_accessor :owner

    def initialize(type, tile)
      @type = type
      @tile = tile

      @owner = nil
    end

    def self.name(type)
      NAMES[type]
    end

    def name
      NAMES[@type]
    end

    def production
      case @type
      when :mine, :well
        { @tile[:resource] => 5 }
      when :farm
        { :food => 5 }
      when :power_station
        { :power => 10 }
      when :nuclear_plant
        { :power => 13 }
      when :wind_farm
        { :power => 8 }
      when :solar_farm
        { :power => 5 }
      when :factory
        { :production => 10 }
      end
    end

  end
end
