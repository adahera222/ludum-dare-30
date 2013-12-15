require 'yogo/ui/tileset'

module YOGO
  module UI
    class Handler

      TEXT_SHOW_SECONDS = 10

      attr_accessor :active
      attr_reader :text

      def initialize
        @text = []
        @active = false
      end

      def tileset
        @tileset ||= YOGO::UI::Tileset.new
      end

      def update(container, delta)
        @text = @text.collect { |text|
          text[:expires] -= delta
          return text unless text[:expires] <= 0.0
        }.compact
      end

      def render(container, graphics)
        if @active then
        end
      end

      def turn!
        @notices = []
      end

      def show_text(pos, content)
        text = { :pos => pos, :content => content, :expires => TEXT_SHOW_SECONDS * 1000 }
        @text << text
      end

      def notice(message)
        # TODO: Show a history item
        puts message
      end

      def immediate(message)
        puts message
      end

      def location_alert(message, tile)
        # TODO: Show a history item that takes you to this spot
        puts message
      end

    end
  end
end
