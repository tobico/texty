module Texty
  class Window < Container
    attr_accessor :title
    
    def draw_to_screen
      Ncurses.erase
      draw_to_region 0, 0, Ncurses.COLS, Ncurses.LINES
      Ncurses.refresh
    end
  end
end