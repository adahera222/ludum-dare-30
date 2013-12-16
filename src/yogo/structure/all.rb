require 'yogo/structure/mine'
require 'yogo/structure/well'
require 'yogo/structure/city'
require 'yogo/structure/farm'
require 'yogo/structure/fishing_fleet'
require 'yogo/structure/coal_power_station'
require 'yogo/structure/oil_power_station'
require 'yogo/structure/nuclear_plant'
require 'yogo/structure/wind_farm'

module YOGO
  module Structure

    STRUCTURES = {
      :mine => Mine,
      :well => Well,
      :city => City,
      :farm => Farm,
      :fishing_fleet => FishingFleet,
      :coal_power_station => CoalPowerStation,
      :oil_power_station => OilPowerStation,
      :nuclear_plant => NuclearPlant,
      :wind_farm => WindFarm,
    }
  end
end
