module Texty
  class Application
    include Bindings
    
    attr :running, :screen, :window
    
    def initialize options = {}
      self.window = options[:window] || nil
    end
    
    attr_reader :window
    def window= window
      @window = window
      window.focus if window
    end
    
    def run
      @screen = Screen.new
      window.screen = screen
      @running = true
      @key_state = :normal
      while running
        main_loop
      end
    ensure
      screen.close
    end
    
    def terminate
      @running = false
    end
    
    def main_loop
      window.redraw
      key = screen.get_key
      return terminate if (key == :ctrl_c)
      @window.key_press key if key
    end
  end
end
