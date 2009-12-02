module Texty
  module Scrollable
    @scroll_y = 0
    
    attr_reader :scroll_y
    def scroll_y= value
      if value < 0
        @scroll_y = 0
      elsif value > @items.length - @last_h
        @scroll_y = @items.length - @last_h
      else
        @scroll_y = value
      end
      trigger :scrolled_y, value if value
    end
    
    def page_up
      self.scroll_y -= @last_h if @last_h
    end
    
    def page_down
      self.scroll_y += @last_h if @last_h
    end
    
  private
    def draw_scrollbar x, y, h, total_height, offset
      return unless h < total_height
      bar_height = [h * h / total_height, 2].max
      bar_offset = offset * (h-bar_height) / (total_height - h)
      Ncurses.attron Ncurses::A_REVERSE
      Ncurses.mvaddch y+bar_offset, x, Ncurses::ACS_UARROW
      if bar_height > 2
        (y+bar_offset+1..y+bar_offset+bar_height-2).each do |cy|
          Ncurses.mvaddch cy, x, ?\s
        end
      end
      Ncurses.mvaddch y+bar_offset+bar_height-1, x, Ncurses::ACS_DARROW
      Ncurses.attroff Ncurses::A_REVERSE
    end
  end
end