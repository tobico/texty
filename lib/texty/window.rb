module Texty
  class Window < Container
    attr_accessor :title
    
    def draw_to_screen
      Screen.clear
      draw_to_region 0, 0, Screen.width, Screen.height
      Screen.flush
    end
  end
end