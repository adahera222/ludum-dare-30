java_import org.newdawn.slick.state.BasicGameState
java_import org.newdawn.slick.Color
java_import org.newdawn.slick.fills.GradientFill
java_import org.newdawn.slick.geom.Rectangle

module YOGO
  class MapState < BasicGameState

    TILE_SIZE = 32
    SCROLL_SPEED = 0.25
    SIDEBAR_WIDTH = 280
    MINIMAP_WIDTH = SIDEBAR_WIDTH - 4

    def getID
      1
    end

    def render(container, game, graphics)
      draw_map(graphics)
      draw_sidebar(graphics)

      graphics.draw_string("(ESC to exit)", 8, container.height - 30)
    end

    def draw_map(graphics)
      viewport.each do |tile, vpos|
        vx,vy = vpos

        sprite = @tileset.terrain(tile[:terrain])
        sprite.draw(vx, vy)

        if tile[:resource] then
          sprite = @tileset.resource(tile[:resource])
          sprite.draw(vx, vy)
        end
      end
    end

    def draw_sidebar(graphics)
      sidebar_x = @screen_x - SIDEBAR_WIDTH

      minimap_x = sidebar_x + 2
      minimap_y = 2

      graphics.set_color(@sidebar_background)
      graphics.fill_rect(sidebar_x, 0, SIDEBAR_WIDTH, @screen_y)

      w = (MINIMAP_WIDTH / @map.width).floor
      h = (MINIMAP_WIDTH / @map.height).floor

      if @minimap_buffer then
        @minimap_buffer.draw(sidebar_x + 2, 2)
      else

        vx = sidebar_x + 2
        vy = 2

        0.upto(@map.maxx) do |x|
          0.upto(@map.maxy) do |y|
            tile = @map[[x,y]]
            if tile[:resource] then
              color = @tileset.resource_color(tile[:resource])
            else
              color = @tileset.terrain_color(tile[:terrain])
            end
            graphics.set_color(color)
            graphics.fill_rect(vx, vy, w, h)
            vy += h
          end
          vy = 2
          vx += w
        end

        @minimap_buffer = Image.new(MINIMAP_WIDTH, MINIMAP_WIDTH)
        graphics.copy_area(@minimap_buffer, sidebar_x + 2, 2)
      end

      graphics.set_color(@minimap_rect)
      graphics.draw_rect(minimap_x + (@map_min_x * w),
                         minimap_y + (@map_min_y * h),
                         (@map_max_x - @map_min_x) * w,
                         (@map_max_y - @map_min_y) * h)
    end

    def init(container, game)
      @game = game
      @ui_handler = game.ui_handler
      @tileset = @ui_handler.tileset
      @world = game.world
      @map = @world.map

      @screen_x = container.width
      @screen_y = container.height

      @view_x = (@world.map.width / 2.0)
      @view_y = (@world.map.height / 2.0)

      @mapview_x = @screen_x - SIDEBAR_WIDTH
      @mapview_y = @screen_y

      @range_x = ((@mapview_x / TILE_SIZE) / 2).floor
      @range_y = ((@mapview_y / TILE_SIZE) / 2).floor

      @sidebar_background = Color.new(0.2, 0.2, 0.2, 1.0)
      @minimap_rect = Color.new(1.0,1.0,1.0,0.8)
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

      @map_min_x = viewx - @range_x
      @map_max_x = viewx + @range_x
      @map_min_y = viewy - @range_y
      @map_max_y = viewy + @range_y

      @map_min_x.upto(@map_max_x) do |x|
        @map_min_y.upto(@map_max_y) do |y|
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
