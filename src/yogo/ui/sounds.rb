import org.newdawn.slick.openal.Audio
import org.newdawn.slick.openal.AudioLoader
import org.newdawn.slick.util.ResourceLoader
import org.newdawn.slick.openal.SoundStore

module YOGO
  module UI
    class Sounds

      REPEAT_FREQUENCY = {
        :build => 1000.0,
        :critical => 1000.0,
        :notification => 1500.0,
        :select => 250.0,
        :invalid => 250.0
      }

      def initialize
        @sounds = {}
        %w( build critical notification select invalid ).each do |sound|
          @sounds[sound.intern] = AudioLoader.getAudio("WAV", ResourceLoader.getResourceAsStream("data/sounds/#{sound}.wav"))
        end

        @repeat = {}
      end

      def update(delta)
        @repeat.each { |s,v| @repeat[s] -= delta }
        @repeat.reject! { |s,v| v < 0.0 }
      end

      def play(sound)
        @repeat[sound] ||= 0.0
        if @repeat[sound] <= 0.0 then
          @sounds[sound].play_as_sound_effect(1.0, 1.0, false) unless @sounds[sound].nil?
          @repeat[sound] += REPEAT_FREQUENCY[sound]
        end
      end

    end
  end
end
