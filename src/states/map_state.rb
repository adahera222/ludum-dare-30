java_import org.newdawn.slick.state.BasicGameState
java_import org.newdawn.slick.Color
java_import org.newdawn.slick.PackedSpriteSheet
java_import org.newdawn.slick.fills.GradientFill
java_import org.newdawn.slick.geom.Rectangle

module YOGO
  class MapState < BasicGameState

    TILE_SIZE = 32

    def getID
      1
    end

    def render(container, game, graphics)
      viewport.each do |tile, vpos|
        vx,vy = vpos

        graphics.set_color(Color.new(1.0,1.0,1.0,1.0))
        graphics.draw_rect(vx, vy, TILE_SIZE, TILE_SIZE)
      end

      graphics.draw_string("(ESC to exit)", 8, container.height - 30)
    end

    def init(container, game)
      @game = game
      @ui_handler = game.ui_handler
      @world = game.world
      @map = @world.map

      @screen_x = container.width
      @screen_y = container.height

      @view_x = (@world.map.width / 2).floor
      @view_y = (@world.map.height / 2).floor

      @range_x = ((@screen_x / TILE_SIZE) / 2).floor
      @range_y = ((@screen_y / TILE_SIZE) / 2).floor
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

    def viewport
      return @viewport if @viewport

      @viewport = {}

      vx = 0
      vy = 0
       
      (@view_x - @range_x).upto(@view_x + @range_x) do |x|
        (@view_y - @range_y).upto(@view_y + @range_y) do |y|
          vy += TILE_SIZE

          pos = [x,y]
          tile = @map[pos]
          next if tile.nil?

          @viewport[tile] = [vx, vy]
        end
        vy = 0
        vx += TILE_SIZE
      end
      @viewport
    end

  end
end
