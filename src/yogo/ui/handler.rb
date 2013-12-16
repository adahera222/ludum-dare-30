require 'yogo/ui/tileset'
require 'yogo/ui/fonts'

module YOGO
  module UI
    class Handler

      TEXT_SHOW_TIME = 10000.0
      TEXT_THROTTLE_TIME = 500.0

      attr_accessor :active
      attr_reader :text
      attr_accessor :game

      def initialize
        @game = nil
        @text = []
        @list = []
        @critical = []
        @active = false
        @font_color = Color.new(1.0, 1.0, 1.0, 1.0)
        @critical_color = Color.new(1.0, 0.3, 0.3, 1.0)
        @timer = 0.0
      end

      def tileset
        @tileset ||= YOGO::UI::Tileset.new
      end

      def fonts
        @font ||= YOGO::UI::Fonts.new
      end

      def update(container, delta)
        if @text.length == 0
          @timer = 0.0
        else
          if @list.length == 0 then
            @timer = 100000.0
          else
            @timer += delta
          end
        end

        if @timer >= TEXT_THROTTLE_TIME then
          msg = @text.shift
          @list.unshift([ msg, TEXT_SHOW_TIME ])
          @timer = 0.0
        end

        expire_message_list(@list, delta)
        expire_message_list(@critical, delta)
      end

      def render(container, graphics)
        vx = 20
        vy = 20

        graphics.set_font(fonts.default)
        @list.each do |data|
          message = data[0]
          if data[1] < 2000.0 then
            i = data[1] / 2000.00
          else
            i = 1.0
          end
          graphics.set_color(@font_color.multiply(Color.new(1.0, 1.0, 1.0, i)))
          graphics.draw_string(message, vx, vy)
          vy += 16
        end

        @huge_height ||= fonts.huge.getHeight('Thequickbrownfox')
        ch = @critical.length * (@huge_height + 5)
        cy = (container.height / 2) - (ch / 2)
        @critical.each do |data|
          message = data[0]
          if data[1] < 2000.0 then
            i = data[1] / 2000.00
          else
            i = 1.0
          end
          graphics.set_font(fonts.huge)
          graphics.set_color(@critical_color.multiply(Color.new(1.0, 1.0, 1.0, i)))
          graphics.draw_string(message, (container.width/2) - (fonts.huge.get_width(message)/2), cy)
          cy += @huge_height + 5
        end
        graphics.set_font(fonts.default)
      end

      def turn!
        @text = []
        @list = []
        @critical.each { |data| data[1] = [ data[1], 1500.0 ].min }
        immediate("A new turn begins...")
      end

      def notice(message)
        @text << message
      end

      def immediate(message)
        @list.unshift([ message, TEXT_SHOW_TIME ])
      end

      def location_alert(message, tile)
        # TODO: Show a history item that takes you to this spot
        @text << message
      end

      def critical(message)
        @critical << [ message, TEXT_SHOW_TIME * 2 ]
      end

      def game_over!(message)
        critical(message)
        @game.running = false
      end

    private

      def expire_message_list(array, delta)
        array.each do |data|
          data[1] -= delta
        end
        array.reject! { |data| data[1] < 0.0 }
      end

    end
  end
end
