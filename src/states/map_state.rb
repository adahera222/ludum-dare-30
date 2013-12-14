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

    KEYS = {
      'm' => [ :mine, :well ],
      'c' => [ :factory ],
      'i' => [ :sawmill ],
      'f' => [ :farm, :fishing_fleet ],
      'p' => [ :power_station ],
      'n' => [ :nuclear_power ],
      'b' => [ :wind_farm ],
      'l' => [ :plantation ],
      'o' => [ :dock, :foundry ]
    }

    STRUCTURE_TEXT = {
      :mine => 'mine',
      :factory => 'factory',
      :power_station => 'powerplant',
      :well => 'well'
    }

    def getID
      1
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
      @current_selected = nil

      @mapview_x = @screen_x - SIDEBAR_WIDTH
      @mapview_y = @screen_y

      @range_x = ((@mapview_x / TILE_SIZE) / 2).floor
      @range_y = ((@mapview_y / TILE_SIZE) / 2).floor

      @sidebar_background = Color.new(0.2, 0.2, 0.2, 1.0)
      @minimap_background = Color.new(0.1, 0.1, 0.1, 1.0)
      @minimap_rect = Color.new(1.0,1.0,1.0,0.8)
    end

    def render(container, game, graphics)
      draw_map(graphics)
      draw_sidebar(graphics)

      graphics.draw_string("(ESC to exit)", 8, container.height - 30)
    end

    def update(container, game, delta)
      input = container.get_input
      container.exit if input.is_key_down(Input::KEY_ESCAPE)

      @ui_handler.update(container, delta)
      @world.update(container, delta)

      if input.is_key_down(Input::KEY_W)
        unless @view_y - SCROLL_SPEED < @range_y
          @view_y -= SCROLL_SPEED
          reset_viewport
        end
      elsif input.is_key_down(Input::KEY_S)
        unless @view_y + SCROLL_SPEED > @map.height - @range_y
          @view_y += SCROLL_SPEED
          reset_viewport
        end
      elsif input.is_key_down(Input::KEY_A)
        unless @view_x - SCROLL_SPEED < @range_x
          @view_x -= SCROLL_SPEED
          reset_viewport
        end
      elsif input.is_key_down(Input::KEY_D)
        unless @view_x + SCROLL_SPEED > @map.width - @range_x
          @view_x += SCROLL_SPEED
          reset_viewport
        end
      end
    end

    def keyPressed(keycode, char)
      if @current_selected then
        return if %w( w a s d ).include?(char.chr)
        building = nil
        KEYS.each do |key, structures|
          if char == key.ord then
            avail = @current_selected.valid_structures
            structures.each do |type|
              if avail.include?(type) then
                puts "BUILDING: #{type}"
                building = type
                break
              end
            end
          end
        end
        puts "UNKNOWN: #{char}" if building.nil?
      end
    end

    def mouseClicked(button, x, y, count)
      if x > @screen_x - SIDEBAR_WIDTH then
        # TODO: Handle sidebar click
      else
        # Handle map click
        rx = (x / TILE_SIZE).floor
        ry = (y / TILE_SIZE).floor

        tx = @map_min_x + rx
        ty = @map_min_y + ry

        puts "Rel: #{[rx, ry].inspect} => Tile: #{[tx, ty].inspect}"
        @current_selected = @map[[tx, ty]]
      end
    end

  private

    def reset_viewport
      @viewport = nil
      @terrain_buffer = nil
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
          pos = [x,y]
          tile = @map[pos]
          next if tile.nil?

          @viewport[tile] = [vx, vy]
          vy += TILE_SIZE
        end
        vy = 0
        vx += TILE_SIZE
      end
      @viewport
    end

    def draw_map(graphics)
      if @terrain_buffer then
        @terrain_buffer.draw(0,0)
      else
        viewport.each do |tile, vpos|
          vx,vy = vpos

          render_tile(tile, vx, vy)

          if tile == @current_selected then
            @tileset.selected.draw(vx, vy)
          end
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
        mx = sidebar_x + 2
        my = 2

        graphics.set_color(@minimap_background)
        graphics.fill_rect(mx,my, MINIMAP_WIDTH, MINIMAP_WIDTH)

        vx = mx
        vy = my

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

      draw_tile_data(graphics)
    end

    def render_tile(tile, vx, vy)
      sprite = @tileset.terrain(tile[:terrain])
      sprite.draw(vx, vy)

      if tile[:resource] then
        sprite = @tileset.resource(tile[:resource])
        sprite.draw(vx, vy)
      end
    end

    def draw_tile_data(graphics)
      return if @current_selected.nil?

      data_x = @screen_x - SIDEBAR_WIDTH + 5
      data_y = MINIMAP_WIDTH + 5

      render_tile(@current_selected, data_x, data_y)
      graphics.draw_string(@current_selected.terrain_name, data_x + 5 + TILE_SIZE, data_y)

      if @current_selected[:resource] then
        graphics.draw_string(@current_selected.resource_name, data_x + 5 + TILE_SIZE, data_y + 16)
      end

      buttons_x = data_x
      buttons_y = data_y + TILE_SIZE + 5

      tile_buffer = Image.new(TILE_SIZE, TILE_SIZE)
      graphics.copy_area(tile_buffer, data_x, data_y)

      # Draw out the structures we can construct here
      @current_selected.valid_structures.each_with_index do |type, idx|
        vx = buttons_x
        vy = buttons_y + (idx * (TILE_SIZE + 5))

        key = KEYS.find { |k, s| s.include?(type) }

        tile_buffer.draw(vx, vy)
        @tileset.structure(type).draw(vx, vy)
        graphics.draw_string("(#{key[0]}) #{STRUCTURE_TEXT[type]}", vx + 5 + TILE_SIZE, vy)
      end

    end

  end
end
