module Texty
  class Window < Container
    attr_accessor :title
    
    def redraw
      screen.clear
      super
      screen.flush
    end
  end
end
