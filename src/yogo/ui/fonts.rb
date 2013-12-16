java_import org.newdawn.slick.TrueTypeFont
java_import org.newdawn.slick.util.ResourceLoader
java_import java.awt.Font

module YOGO
  module UI
    class Fonts

      attr_reader :default, :huge

      def initialize
        input = ResourceLoader.getResourceAsStream("data/fonts/Arimo-Regular.ttf");
        font = Font.createFont(Font::TRUETYPE_FONT, input)

        regular = font.deriveFont(14.0)
        @default = TrueTypeFont.new(regular, false)

        input = ResourceLoader.getResourceAsStream("data/fonts/Arimo-Bold.ttf");
        font = Font.createFont(Font::TRUETYPE_FONT, input)
        huge = font.deriveFont(28.0)
        @huge = TrueTypeFont.new(huge, false)
      end

    end
  end
end
