module Texty
  class Application
    include Bindings
    
    attr_accessor :running
    
    def initialize options = {}
      self.window = options[:window] || nil
    end
    
    attr_reader :window
    def window= window
      @window = window
      window.focus if window
    end
    
    def run
      Screen.activate do
        @running = true
        @key_state = :normal
        while running
          main_loop
        end
      end
    end
    
    def terminate
      @running = false
    end
    
    def main_loop
      @window.draw_to_screen
      key = Screen.get_key
      return terminate if (key == :ctrl_c)
      @window.key_press key if key
    end
  end
end