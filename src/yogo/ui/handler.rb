require 'yogo/ui/tileset'

module YOGO
  module UI
    class Handler

      TEXT_SHOW_TIME = 10000.0
      TEXT_THROTTLE_TIME = 500.0

      attr_accessor :active
      attr_reader :text

      def initialize
        @text = []
        @list = []
        @active = false
        @font_color = Color.new(1.0, 1.0, 1.0, 1.0)
        @timer = 0.0
      end

      def tileset
        @tileset ||= YOGO::UI::Tileset.new
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

        @list.each do |data|
          data[1] -= delta
        end

        @list.reject! { |data| data[1] < 0.0 }
      end

      def render(container, graphics)
        vx = 20
        vy = 20

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
      end

      def turn!
        @notices = []
      end

      def notice(message)
        # TODO: Show a history item
        puts message
        @text << message
      end

      def immediate(message)
        puts message
        @list.unshift([ message, TEXT_SHOW_TIME ])
      end

      def location_alert(message, tile)
        # TODO: Show a history item that takes you to this spot
        puts message
        @text << message
      end

    end
  end
end
