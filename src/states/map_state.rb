java_import org.newdawn.slick.state.BasicGameState
java_import org.newdawn.slick.Color
java_import org.newdawn.slick.PackedSpriteSheet
java_import org.newdawn.slick.fills.GradientFill
java_import org.newdawn.slick.geom.Rectangle

module YOGO
  class MapState < BasicGameState

    TILE_SIZE = 6
    SCROLL_SPEED = 0.25

    def getID
      1
    end

    def render(container, game, graphics)
      viewport.each do |tile, vpos|
        vx,vy = vpos

        if tile[:terrain] == :land then
          graphics.set_color(Color.new(0.0,1.0,0.0,1.0))
        elsif tile[:terrain] == :hills then
          graphics.set_color(Color.new(0.0,0.5,0.0,1.0))
        elsif tile[:terrain] == :mountain then
          graphics.set_color(Color.new(0.5,0.5,0.5,1.0))
        else
          graphics.set_color(Color.new(0,0,1.0,1.0))
        end
        graphics.fill_rect(vx, vy, TILE_SIZE, TILE_SIZE)
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

      @view_x = (@world.map.width / 2.0)
      @view_y = (@world.map.height / 2.0)

      @range_x = ((@screen_x / TILE_SIZE) / 2).floor
      @range_y = ((@screen_y / TILE_SIZE) / 2).floor
    end

    def update(container, game, delta)
      input = container.get_input
      container.exit if input.is_key_down(Input::KEY_ESCAPE)

      @ui_handler.update(container, delta)
      @world.update(container, delta)

      if input.is_key_down(Input::KEY_W)
        @view_y -= SCROLL_SPEED
        reset_viewport
      elsif input.is_key_down(Input::KEY_S)
        @view_y += SCROLL_SPEED
        reset_viewport
      elsif input.is_key_down(Input::KEY_A)
        @view_x -= SCROLL_SPEED
        reset_viewport
      elsif input.is_key_down(Input::KEY_D)
        @view_x += SCROLL_SPEED
        reset_viewport
      end
    end

    def mouseClicked(button, x, y, count)
    end

  private

    def reset_viewport
      @viewport = nil
    end

    def viewport
      return @viewport if @viewport

      @viewport = {}

      viewx = @view_x.floor
      viewy = @view_y.floor

      vx = 0
      vy = 0
       
      (viewx - @range_x).upto(viewx + @range_x) do |x|
        (viewy - @range_y).upto(viewy + @range_y) do |y|
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
