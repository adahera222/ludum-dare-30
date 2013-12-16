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
      'f' => [ :farm, :fishing_fleet ],
      'p' => [ :coal_power_station ],
      'o' => [ :oil_power_station ],
      'n' => [ :nuclear_plant ],
      'b' => [ :wind_farm ],
      'y' => [ :foundry ]
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
      @player = @world.player

      @screen_x = container.width
      @screen_y = container.height

      @view_x = (@world.map.width / 2.0)
      @view_y = (@world.map.height / 2.0)
      @current_selected = nil

      @mapview_x = @screen_x - SIDEBAR_WIDTH
      @mapview_y = @screen_y

      @range_x = ((@mapview_x / TILE_SIZE) / 2).floor
      @range_y = ((@mapview_y / TILE_SIZE) / 2).floor

      @minimap_mode = nil

      @sidebar_background = Color.new(0.2, 0.2, 0.2, 1.0)
      @minimap_background = Color.new(0.1, 0.1, 0.1, 1.0)
      @minimap_rect = Color.new(1.0,1.0,1.0,0.8)
      @font_color = Color.new(1.0,1.0,1.0,1.0)
    end

    def render(container, game, graphics)
      if @world.generating? then
        draw_sidebar(graphics)
        graphics.set_color(@font_color)
        graphics.draw_string("Map generating... #{@world.map.unmapped}", container.width / 2, container.height / 2)
        reset_minimap
      else
        draw_map(graphics)
        draw_sidebar(graphics)
      end

      @ui_handler.render(container, graphics)

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
      if char == 13 then
        @world.turn!
        reset_viewport
        reset_minimap
        return
      end

      if keycode == Input::KEY_F1 then
        @minimap_mode = nil
        reset_minimap
      end

      if keycode == Input::KEY_F2 then
        @minimap_mode = :countries
        reset_minimap
      end

      if @current_selected then
        return if %w( w a s d ).include?(char.chr)

        if @current_selected.structure && @current_selected.structure.is_a?(Structure::City) then
          city = @current_selected.structure
          state = city.owner
          case char.chr
          when '-'
            # Lobby lower air tax
            state.lobby(:air_pollution, -1.0, @player)
            @player.balance -= 1.0
            @ui_handler.immediate("You invest $1m lobbying for lower air pollution regulation")
          when '='
            # Lobby raise air tax
            state.lobby(:air_pollution, 1.0, @player)
            @player.balance -= 1.0
            @ui_handler.immediate("You invest $1m lobbying for greater air pollution regulation")
          when '['
            # Lobby lower water tax
            state.lobby(:water_pollution, -1.0, @player)
            @player.balance -= 1.0
            @ui_handler.immediate("You invest $1m lobbying for lower water pollution regulation")
          when '='
            # Lobby raise water tax
            state.lobby(:water_pollution, 1.0, @player)
            @player.balance -= 1.0
            @ui_handler.immediate("You invest $1m lobbying for greater water pollution regulation")
          end

        elsif @current_selected.structure.nil? then
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
          if building then
            price = Structure.price(building)
            if price > @player.balance then
              @ui_handler.immediate("A #{Structure.name(building)} costs $#{price}m but you only have #{sprintf('$%.2fm', @player.balance)}")
            else
              @player.balance -= price
              s = Structure.create(building, @current_selected)
              s.owner = @world.player
              @current_selected[:structure] = s
              reset_minimap
              @ui_handler.immediate("You have built a new #{s.name} in #{@current_selected.state.name}")
            end
          else
            puts "UNKNOWN: #{char}"
          end
        end
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
        reset_viewport
        reset_minimap
      end
    end

  private

    def reset_viewport
      @viewport = nil
      @terrain_buffer = nil
    end

    def reset_minimap
      @minimap_buffer = nil
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
      cities = []
      if @terrain_buffer then
        @terrain_buffer.draw(0,0)
      else
        viewport.each do |tile, vpos|
          vx,vy = vpos

          if tile.structure.is_a?(Structure::City) then
            cities << [ tile.structure, vx, vy ]
          end

          render_tile(tile, vx, vy, graphics)

          if tile == @current_selected then
            @tileset.selected.draw(vx, vy)
          end
        end
      end

      graphics.set_color(@font_color)
      cities.each do |data|
        w = graphics.get_font.get_width(data[0].name)
        text_x = data[1] + (TILE_SIZE / 2) - (w/2)
        text_y = data[2] - 20
        graphics.draw_string(data[0].name, text_x, text_y)
      end
    end

    def draw_sidebar(graphics)
      sidebar_x = @screen_x - SIDEBAR_WIDTH

      graphics.set_color(@sidebar_background)
      graphics.fill_rect(sidebar_x, 0, SIDEBAR_WIDTH, @screen_y)

      sprite = @tileset.ui(:cash)
      sprite.draw(sidebar_x + 2, 2)
      graphics.set_color(@font_color)
      graphics.draw_string(sprintf('$%.2fm', @world.player.balance), sidebar_x + 2 + 4 + TILE_SIZE, 10)

      minimap_x = sidebar_x + 2
      minimap_y = 2 + TILE_SIZE + 5

      w = (MINIMAP_WIDTH / @map.width).floor
      h = (MINIMAP_WIDTH / @map.height).floor

      if @minimap_buffer then
        @minimap_buffer.draw(minimap_x, minimap_y)
      else
        mx = sidebar_x + 2
        my = minimap_y

        graphics.set_color(@minimap_background)
        graphics.fill_rect(mx,my, MINIMAP_WIDTH, MINIMAP_WIDTH)

        vx = mx
        vy = my

        0.upto(@map.maxx) do |x|
          0.upto(@map.maxy) do |y|
            tile = @map[[x,y]]
            if tile.structure then
              color = @tileset.structure_color(tile.structure)
            elsif tile.resource then
              color = @tileset.resource_color(tile.resource)
            else
              color = @tileset.terrain_color(tile.terrain)
            end
            graphics.set_color(color)
            graphics.fill_rect(vx, vy, w, h)

            if @minimap_mode == :countries || @current_selected && @current_selected.structure.is_a?(Structure::City) then
              color = nil
              if @minimap_mode == :countries then
                if tile.state && tile.state.color then
                  color = tile.state.color.multiply(Color.new(1.0,1.0,1.0,0.5))
                else
                  color = Color.new(0.0, 0.0, 0.0, 0.5)
                end
              else
                if tile.state && tile.state.color && tile.state == @current_selected.structure.owner then
                  color = tile.state.color.multiply(Color.new(1.0,1.0,1.0,0.5))
                end
              end
            end

            if color then
              graphics.set_color(color)
              graphics.fill_rect(vx, vy, w, h)
            end

            vy += h
          end
          vy = minimap_y
          vx += w
        end

        @minimap_buffer = Image.new(MINIMAP_WIDTH, MINIMAP_WIDTH)
        graphics.copy_area(@minimap_buffer, minimap_x, minimap_y)
      end

      if @map_min_x && @map_min_y && @map_max_x && @map_max_y then
        graphics.set_color(@minimap_rect)
        graphics.draw_rect(minimap_x + (@map_min_x * w),
                           minimap_y + (@map_min_y * h),
                           (@map_max_x - @map_min_x) * w,
                           (@map_max_y - @map_min_y) * h)
      end

      draw_tile_data(graphics)
    end

    def render_tile(tile, vx, vy, graphics, overlay=true)
      sprite = @tileset.terrain(tile.terrain)
      sprite.draw(vx, vy)

      if tile.terrain != :water && tile.inundation > 0.25 then
        sprite = @tileset.ui(:swamp)
        sprite.draw(vx, vy, Color.new(1.0,1.0,1.0, tile.inundation * 2.0))
      end

      if tile.water_pollution > 0.05 then
        if tile.terrain == :water then
          sprite = @tileset.ui(:water_pollution)
        else
          sprite = @tileset.ui(:land_pollution)
        end
        sprite.draw(vx, vy, Color.new(1.0,1.0,1.0, tile.water_pollution))
      end

      if tile[:resource] then
        sprite = @tileset.resource(tile[:resource])
        sprite.draw(vx, vy)
      end

      if tile[:structure] then
        sprite = @tileset.structure(tile[:structure].type)
        sprite.draw(vx, vy)
      end

      if tile.air_pollution > 0.05 then
        sprite = @tileset.ui(:air_pollution)
        sprite.draw(vx, vy, Color.new(1.0,1.0,1.0, tile.air_pollution))
      end

      if overlay then
        if @current_selected && @current_selected.structure.is_a?(Structure::City) then
          if tile.state && tile.state.color && tile.state == @current_selected.structure.owner then
            color = @font_color.multiply(Color.new(1.0,1.0,1.0,0.5))
            graphics.set_color(color)
            graphics.fill_rect(vx, vy, TILE_SIZE, TILE_SIZE)
          end
        end
      end
    end

    def draw_tile_data(graphics)
      return if @current_selected.nil?

      data_x = @screen_x - SIDEBAR_WIDTH + 5
      data_y = MINIMAP_WIDTH + 5

      text_x = data_x + 5 + TILE_SIZE

      graphics.set_color(@font_color)

      render_tile(@current_selected, data_x, data_y, graphics, false)
      graphics.draw_string(@current_selected.terrain_name, text_x, data_y)

      if @current_selected[:resource] then
        graphics.draw_string(@current_selected.resource_name, text_x, data_y + 16)
      end

      graphics.draw_string(@current_selected.air_pollution_description, text_x, data_y + TILE_SIZE + 5)
      graphics.draw_string(@current_selected.water_pollution_description, text_x, data_y + TILE_SIZE + 5 + 16)


      buttons_x = data_x
      buttons_y = data_y + (2 * (TILE_SIZE + 5))

      tile_buffer = Image.new(TILE_SIZE, TILE_SIZE)
      graphics.copy_area(tile_buffer, data_x, data_y)

      if @current_selected[:structure].nil? then
        # Draw out the structures we can construct here
        @current_selected.valid_structures.each_with_index do |type, idx|
          vx = buttons_x
          vy = buttons_y + (idx * (TILE_SIZE + 5 + 20))

          key = KEYS.find { |k, s| s.include?(type) }

          tile_buffer.draw(vx, vy)
          @tileset.structure(type).draw(vx, vy)
          graphics.draw_string("(#{key[0]}) #{Structure.name(type)}", vx + 5 + TILE_SIZE, vy)
          graphics.draw_string(sprintf("$%dm + $%.1fm/turn", Structure.price(type), Structure.running_cost(type)), vx + 5 + TILE_SIZE, vy + 16)
          graphics.draw_string(Structure.description(type), vx + 5 + TILE_SIZE, vy + 32)
        end
      else
        # Show the structure details
        structure = @current_selected[:structure]

        vx = buttons_x
        vy = buttons_y

        structure.production.each do |item, quantity|
          graphics.draw_string("Produces #{quantity} #{item}", vx, vy)
          vy += 15
        end
        structure.causes.each do |effect, quantity|
          graphics.draw_string("Produces #{sprintf('%0.2f', quantity)} #{effect}", vx, vy)
          vy += 15
        end

        if structure.is_a?(Structure::City) then
          vy += 15
          graphics.draw_string("TAX RATES", vx, vy)
          vy += 15
          graphics.draw_string(sprintf("Air: $%.2f per 1", structure.owner.air_pollution_tax), vx, vy)
          vy += 15
          graphics.draw_string(sprintf("Water: $%.2f per 1 unit", structure.owner.water_pollution_tax), vx, vy)
          vy += 15

          if structure.notes then
            vy += 15
            structure.notes.each do |note|
              graphics.draw_string(note, vx, vy)
              vy += 15
            end
          end
        end

      end

    end

  end
end
