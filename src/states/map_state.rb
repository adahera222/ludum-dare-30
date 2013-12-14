java_import org.newdawn.slick.state.BasicGameState
java_import org.newdawn.slick.Color
java_import org.newdawn.slick.PackedSpriteSheet
java_import org.newdawn.slick.fills.GradientFill
java_import org.newdawn.slick.geom.Rectangle

module YOGO
  class MapState < BasicGameState

    def getID
      1
    end

    def render(container, game, graphics)
      graphics.draw_string("(ESC to exit)", 8, container.height - 30)
    end

    def init(container, game)
      @game = game
      @ui_handler = game.ui_handler
      @world = game.world

      @screen_x = container.width
      @screen_y = container.height
    end

    def update(container, game, delta)
      input = container.get_input
      container.exit if input.is_key_down(Input::KEY_ESCAPE)

      @ui_handler.update(container, delta)
      @world.update(container, delta)
    end

    def mouseClicked(button, x, y, count)
    end

  private

  end
end
