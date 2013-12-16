$:.push File.expand_path('../../lib', __FILE__)
$:.push File.expand_path('../', __FILE__)

require 'java'
require 'lib/lwjgl.jar'
require 'lib/slick.jar'

java_import org.newdawn.slick.state.StateBasedGame
java_import org.newdawn.slick.GameContainer
java_import org.newdawn.slick.Graphics
java_import org.newdawn.slick.Image
java_import org.newdawn.slick.Input
java_import org.newdawn.slick.SlickException
java_import org.newdawn.slick.AppGameContainer

require 'states/map_state'
require 'yogo/world'
require 'yogo/ui/handler'

module YOGO
  class Game < StateBasedGame

    attr_reader :world, :ui_handler
    attr_accessor :running

    def initialize(name)
      @running = false

      @ui_handler = UI::Handler.new
      @ui_handler.game = self

      @world = World.new
      @world.ui_handler = @ui_handler
      @world.game = self

      super
    end

    def player
      @world.player
    end

    def initStatesList(container)
      self.add_state(MapState.new)
    end
  end
end

# WIDTH = 1280
# HEIGHT = 720
# FULLSCREEN = true

WIDTH = 1000
HEIGHT = 700
FULLSCREEN = false

Kernel::srand(5000)

app = AppGameContainer.new(YOGO::Game.new('YOGO'))
app.set_display_mode(WIDTH, HEIGHT, FULLSCREEN)
app.start
