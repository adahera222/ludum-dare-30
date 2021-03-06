require 'date'

java_import org.newdawn.slick.state.BasicGameState
java_import org.newdawn.slick.Color
java_import org.newdawn.slick.fills.GradientFill
java_import org.newdawn.slick.geom.Rectangle

module YOGO
  class MapState < BasicGameState

    TILE_SIZE = 32
    SCROLL_SPEED = 0.25
    SIDEBAR_WIDTH = 280
    MINIMAP_WIDTH = SIDEBAR_WIDTH
    OVERLAY_WIDTH = 300

    KEYS = {
      'm' => [ :iron_mine, :coal_mine, :well ],
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
      @container = container
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

      @default_font = @ui_handler.fonts.default
      @line_height = @default_font.getHeight('Thequickbrownfox')

      @stock_overlay = false
      @opponents_overlay = false
      @menu_overlay = false
      @overlay_background = Color.new(0.0,0.0,0.0,0.8)
    end

    def render(container, game, graphics)
      graphics.set_font(@default_font)
      if @world.generating? then
        draw_sidebar(graphics)
        graphics.set_color(@font_color)
        graphics.draw_string("Map generating... #{@world.map.unmapped}", container.width / 2, container.height / 2)
        reset_minimap
      else
        draw_map(graphics)
        draw_sidebar(graphics)

        if @stock_overlay then
          draw_stock_overlay(graphics)
        end
        if @opponents_overlay then
          draw_opponents_overlay(graphics)
        end

        if @menu_overlay then
          draw_menu_overlay(graphics)
        end
      end

      @ui_handler.render(container, graphics)

      graphics.set_font(@default_font)
    end

    def update(container, game, delta)
      input = container.get_input

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
      @menu_overlay = !@menu_overlay if keycode == Input::KEY_ESCAPE

      if @menu_overlay then
        case char.chr
        when 'q'
          @container.exit
        end
        return
      end

      if @game.running then
        if char == 13 then
          @world.turn!
          reset_viewport
          reset_minimap
          return
        end

        if keycode == Input::KEY_F1 then
          @stock_overlay = !@stock_overlay
        end

        if keycode == Input::KEY_F2 then
          @opponents_overlay = !@opponents_overlay
        end

        if keycode == Input::KEY_F3 then
          if @minimap_mode.nil? then
            @minimap_mode = :countries
          else
            @minimap_mode = nil
          end
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
            when ']'
              # Lobby raise water tax
              state.lobby(:water_pollution, 1.0, @player)
              @player.balance -= 1.0
              @ui_handler.immediate("You invest $1m lobbying for greater water pollution regulation")
            end
          elsif @current_selected.structure && @current_selected.structure.owner == @player then
            case char.chr
            when 'x'
              if @current_selected.structure.running? then
                @current_selected.structure.shutdown!
                @ui_handler.immediate("You have shut down a #{@current_selected.structure.name} temporarily")
              else
                @current_selected.structure.reopen!
                @ui_handler.immediate("You have re-opened a #{@current_selected.structure.name}")
              end
            when 'z'
              # Destroy it entirely
              @ui_handler.location_alert("You have fully decommissioned a #{@current_selected.structure.name}", @current_selected)
              @map.destroy_structure(@current_selected.structure)
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
                @ui_handler.mistake("A #{Structure.name(building)} costs $#{price}m but you only have #{sprintf('$%.2fm', @player.balance)}")
              else
                @player.balance -= price
                s = @map.build_structure(building, @current_selected, @world.player)
                @ui_handler.sounds.play(:build)
                reset_minimap
                @ui_handler.immediate("You have built a new #{s.name} in #{@current_selected.state.name}")
              end
            else
              puts "UNKNOWN: #{char}"
              @ui_handler.sounds.play(:invalid)
            end
          end
        end
      end
    end

    def mouseClicked(button, x, y, count)
      if @game.running then
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

          # if @current_selected.structure && @current_selected.structure.owner == @player then
          #   @ui_handler.sounds.play(:select)
          # end

          reset_viewport
          reset_minimap
        end
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


      tx = sidebar_x + 2 + 4 + 16
      ty = 1

      sprite = @tileset.ui16(:cash)
      sprite.draw(sidebar_x + 2, ty)
      graphics.set_color(@font_color)
      graphics.draw_string(sprintf('$%.2fm', @world.player.balance), tx, ty)

      date = "#{Date::ABBR_MONTHNAMES[@world.month]} #{@world.year}"
      tw = graphics.get_font.get_width(date)
      graphics.draw_string(date, @screen_x - (tw + 4), ty)

      ty += 18
      sprite = @tileset.ui16(:low_temp)
      sprite.draw(sidebar_x + 2, ty)
      sprite = @tileset.ui16(:high_temp)
      sprite.draw(sidebar_x + 2, ty, Color.new(1.0,1.0,1.0, @world.warming_rate))
      graphics.set_color(@font_color)
      graphics.draw_string(sprintf('%d%%', @world.warming_rate * 100.0), tx, ty)

      pop = sprintf('%.1f', @world.population.to_f)
      tw = graphics.get_font.get_width(pop)
      graphics.draw_string(pop, @screen_x - (tw + 4), ty)
      sprite = @tileset.ui16(:person)
      sprite.draw(@screen_x - (tw + 4 + 18), ty)

      minimap_x = sidebar_x
      minimap_y = TILE_SIZE + 5

      w = (MINIMAP_WIDTH / @map.width).floor
      h = (MINIMAP_WIDTH / @map.height).floor

      if @minimap_buffer then
        @minimap_buffer.draw(minimap_x, minimap_y)
      else
        mx = sidebar_x
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
      data_y = MINIMAP_WIDTH + 5 + TILE_SIZE

      text_x = data_x + 5 + TILE_SIZE

      graphics.set_color(@font_color)

      render_tile(@current_selected, data_x, data_y, graphics, false)
      graphics.draw_string(@current_selected.terrain_name, text_x, data_y)

      if @current_selected[:resource] then
        graphics.draw_string(@current_selected.resource_name, text_x, data_y + @line_height)
      end

      tx = data_x + 2
      ty = data_y + TILE_SIZE + 5

      sprite = @tileset.ui16(:clean_air)
      sprite.draw(tx, ty)
      sprite = @tileset.ui16(:dirty_air)
      sprite.draw(tx, ty, Color.new(1.0,1.0,1.0, @current_selected.air_pollution))
      graphics.draw_string(@current_selected.air_pollution_description, tx + 18, ty)

      tw = @default_font.get_width(@current_selected.water_pollution_description)
      tx = @screen_x - tw - 5
      graphics.draw_string(@current_selected.water_pollution_description, tx, ty)

      sprite = @tileset.ui16(:clean_water)
      sprite.draw(tx - 18, ty)
      sprite = @tileset.ui16(:dirty_water)
      sprite.draw(tx - 18, ty, Color.new(1.0,1.0,1.0, @current_selected.water_pollution))

      buttons_x = data_x
      buttons_y = data_y + (TILE_SIZE + 5 + 20)

      tile_buffer = Image.new(TILE_SIZE, TILE_SIZE)
      graphics.copy_area(tile_buffer, data_x, data_y)

      if @current_selected[:structure].nil? then
        # Draw out the structures we can construct here
        @current_selected.valid_structures.each_with_index do |type, idx|
          vx = buttons_x
          vy = buttons_y + (idx * (TILE_SIZE + 2 + @line_height))

          key = KEYS.find { |k, s| s.include?(type) }

          tile_buffer.draw(vx, vy)
          @tileset.structure(type).draw(vx, vy)
          graphics.draw_string("(#{key[0]}) #{Structure.name(type)}", vx + 5 + TILE_SIZE, vy)
          graphics.draw_string(sprintf("$%dm + $%.1fm/turn", Structure.price(type), Structure.running_cost(type)), vx + 5 + TILE_SIZE, vy + @line_height)
          graphics.draw_string(Structure.description(type), vx + 5 + TILE_SIZE, vy + 32)
        end
      else
        # Show the structure details
        structure = @current_selected[:structure]

        vx = buttons_x
        vy = buttons_y

        if structure.profitability then
          if structure.running? then
            graphics.draw_string("Production: #{sprintf('%.0f%%', structure.production_rate * 100.0)}", vx, vy)
          else
            graphics.draw_string("Production: Closed", vx, vy)
          end
          vy += 15
          graphics.draw_string("Profitability: #{sprintf('%.2f%%', structure.profitability * 100.0)}", vx, vy)
          vy += 15
        end

        structure.production.each do |item, quantity|
          graphics.draw_string("Produces #{quantity} #{item}", vx, vy)
          vy += 15
        end
        structure.consumes.each do |item, quantity|
          graphics.draw_string("Consumes #{quantity} #{item}", vx, vy)
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
        elsif structure.owner == @player then
          if structure.running? then
            graphics.draw_string('(x) Temporary Closure', vx, vy)
          else
            graphics.draw_string('(x) Re-open', vx, vy)
          end
          vy += 15
          graphics.draw_string('(z) Decommission', vx, vy)
          vy += 15
        end

      end
    end

    def draw_stock_overlay(graphics)
      graphics.set_color(@overlay_background)
      graphics.fill_rect(50,@screen_y / 2,OVERLAY_WIDTH,(@screen_y / 2) - 50)

      vx = 54
      vy = (@screen_y / 2) + 4


      graphics.set_color(@font_color)
      if @world.market.stocks.keys.length == 0 then
        graphics.draw_string("Commodity prices are available next turn", vx, vy)
        vy += 20
      else
        @world.market.stocks.keys.each do |c|
          graphics.draw_string("#{Market::COMMODITY_NAMES[c]} @ #{sprintf('$%.3fm', @world.market.price(c))}", vx, vy)
          vy += 15
          graphics.draw_string("Stockpiled: #{@world.market.available(c)} #{sprintf('%+d', -@world.market.live_demand[c])}", vx, vy)
          vy += 20
        end
      end
    end

    def draw_opponents_overlay(graphics)
      graphics.set_color(@overlay_background)
      vx = @screen_x - SIDEBAR_WIDTH - OVERLAY_WIDTH - 50
      vy = @screen_y / 2
      graphics.fill_rect(vx, vy,OVERLAY_WIDTH,(@screen_y / 2) - 50)

      vx += 4
      vy += 4

      graphics.set_color(@font_color)
      @world.map.entities.each do |entity|
        next unless entity.is_a?(Entity::Corporation)

        if entity.running? then
          graphics.draw_string("#{entity.name} #{sprintf('$%.1fm', entity.balance)}", vx, vy)
        else
          graphics.draw_string("#{entity.name} BANKRUPT", vx, vy)
        end
        vy += 20
      end
    end

    def draw_menu_overlay(graphics)
      graphics.set_color(@overlay_background)
      graphics.fill_rect(0, 0, @screen_x, @screen_y)
      graphics.fill_rect(50, 50, @screen_x - 50, @screen_y - 50)

      [ 'MENU', 'q - quit' ].each_with_index do |line, idx|
        tw = @default_font.get_width(line)
        graphics.set_color(@font_color)
        graphics.draw_string(line, (@screen_x / 2) - (tw/2), (@screen_y / 2) + (idx * 18))
      end
    end
  end
end
