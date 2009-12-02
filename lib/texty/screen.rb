module Texty
  class Screen
    def self.draw_border x, y, w, h
      Ncurses.mvhline y,      x+1,    Ncurses::ACS_HLINE,   w-2
      Ncurses.mvhline y+h-1,  x+1,    Ncurses::ACS_HLINE,   w-2
      Ncurses.mvvline y+1,    x,      Ncurses::ACS_VLINE,   h-2
      Ncurses.mvvline y+1,    x+w-1,  Ncurses::ACS_VLINE,   h-2
      Ncurses.mvaddch y,      x,      Ncurses::ACS_ULCORNER
      Ncurses.mvaddch y,      x+w-1,  Ncurses::ACS_URCORNER
      Ncurses.mvaddch y+h-1,  x,      Ncurses::ACS_LLCORNER
      Ncurses.mvaddch y+h-1,  x+w-1,  Ncurses::ACS_LRCORNER
    end
    
    def self.print_line x, y, w, text
      Ncurses.move y, x
      Ncurses.addnstr text, w
    end
    
    def self.print_line_with_style x, y, w, style, text
      a = style_to_attr style
      Ncurses.attron a unless a == 0
      self.print_line x, y, w, text
      Ncurses.attroff a unless a == 0
    end
    
    def self.style_to_attr style
      if style[:selected]
        if style[:active]
          if style[:color] == :red
            Ncurses.COLOR_PAIR(2) | Ncurses::A_REVERSE
          elsif style[:color] == :green
            Ncurses.COLOR_PAIR(3) | Ncurses::A_REVERSE
          else
            Ncurses.COLOR_PAIR(1) | Ncurses::A_REVERSE
          end
        else
          if style[:color] == :red
            Ncurses.COLOR_PAIR(4)
          elsif style[:color] == :green
            Ncurses.COLOR_PAIR(5)
          else
            Ncurses::A_REVERSE
          end
        end
      else
        if style[:color] == :red
          Ncurses.COLOR_PAIR(2)
        elsif style[:color] == :green
          Ncurses.COLOR_PAIR(3)
        elsif style[:color] == :blue
          Ncurses.COLOR_PAIR(1)
        else
          0
        end
      end
    end
  end
end