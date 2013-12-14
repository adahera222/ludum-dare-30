java_import org.newdawn.slick.PackedSpriteSheet

module YOGO
  module UI
    class Tileset

      TERRAIN = [ :water, :grass, :hills, :mountains, :swamp ]

      def initialize
        @sheet = PackedSpriteSheet.new("data/yogo.def")
        @tiles = {
          :terrain => {}
        }

        TERRAIN.each_with_index do |name, idx|
          @tiles[:terrain][name] = @sheet.get_sprite("terrain_#{idx}.png")
        end
      end

      def terrain(type)
        @tiles[:terrain][type] || @tiles[:terrain][:water]
      end

    end
  end
end
