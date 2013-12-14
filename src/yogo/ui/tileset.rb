java_import org.newdawn.slick.PackedSpriteSheet

module YOGO
  module UI
    class Tileset

      TERRAIN = [ :water, :grass, :hills, :mountains, :swamp ]
      RESOURCES = [ :oil, :coal, :iron, :uranium, :aluminum, :fish, :arable, :blank ]

      def initialize
        @sheet = PackedSpriteSheet.new("data/yogo.def")
        @tiles = {
          :terrain => {},
          :resource => {}
        }

        TERRAIN.each_with_index do |name, idx|
          @tiles[:terrain][name] = @sheet.get_sprite("terrain_#{idx}.png")
        end

        RESOURCES.each_with_index do |name, idx|
          @tiles[:resource][name] = @sheet.get_sprite("resources_#{idx}.png")
        end
      end

      def terrain(type)
        @tiles[:terrain][type] || @tiles[:terrain][:water]
      end

      def resource(type)
        @tiles[:resource][type] || @tiles[:resource][:blank]
      end

    end
  end
end
