require 'yogo/ui/tileset'

module YOGO
  module UI
    class Handler

      TEXT_SHOW_SECONDS = 10

      attr_reader :text

      def initialize
        @text = []
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

      def show_text(pos, content)
        text = { :pos => pos, :content => content, :expires => TEXT_SHOW_SECONDS * 1000 }
        @text << text
      end

    end
  end
end
