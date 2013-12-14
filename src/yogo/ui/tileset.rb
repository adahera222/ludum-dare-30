java_import org.newdawn.slick.PackedSpriteSheet

module YOGO
  module UI
    class Tileset

      TERRAIN = [ :water, :grass, :hills, :mountains, :swamp ]
      RESOURCES = [ :oil, :coal, :iron, :uranium, :aluminum, :fish, :arable, :blank ]

      TERRAIN_COLORS = { :water => Color.new(14, 53, 75, 255),
                         :grass => Color.new(69, 145, 26, 255),
                         :hills => Color.new(27, 52, 43, 255),
                         :mountains => Color.new(79, 79, 79, 255),
                         :swamp => Color.new(30, 85, 55, 255)
      }

      RESOURCE_COLORS = { :oil => Color.new(0,0,0,255),
                          :coal => Color.new(33,33,33,255),
                          :iron => Color.new(113,31,31,255),
                          :uranium => Color.new(190,222,44,255),
                          :aluminium => Color.new(79,79,79,255),
                          :fish => Color.new(136,199,234,255),
                          :arable => Color.new(121, 191, 29, 255),
                          :blank => Color.new(184,37,53,255)
      }

      def initialize
        @sheet = PackedSpriteSheet.new("data/yogo.def")
        @tiles = {
          :terrain => {},
          :resource => {},
          :ui => {}
        }

        TERRAIN.each_with_index do |name, idx|
          @tiles[:terrain][name] = @sheet.get_sprite("terrain_#{idx}.png")
        end

        RESOURCES.each_with_index do |name, idx|
          @tiles[:resource][name] = @sheet.get_sprite("resources_#{idx}.png")
        end

        @tiles[:ui][:selected] = @sheet.get_sprite("ui_0.png")
      end

      def terrain(type)
        @tiles[:terrain][type] || @tiles[:terrain][:water]
      end

      def resource(type)
        @tiles[:resource][type] || @tiles[:resource][:blank]
      end

      def terrain_color(type)
        TERRAIN_COLORS[type] || TERRAIN_COLORS[:water]
      end

      def resource_color(type)
        RESOURCE_COLORS[type] || RESOURCE_COLORS[:blank]
      end

      def selected
        @tiles[:ui][:selected]
      end

    end
  end
end
