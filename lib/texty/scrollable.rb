module Texty
  module Scrollable
    @scroll_y = 0
    
    attr_reader :scroll_y
    def scroll_y= value
      return unless can_scroll?
      if value < 0
        @scroll_y = 0
      elsif value > @scroll_height - @last_h
        @scroll_y = @scroll_height - @last_h
      else
        @scroll_y = value
      end
      trigger :scrolled_y, value if value
    end
    
    def can_scroll?
      @last_h && @scroll_height > @last_h
    end
    
    def page_up
      self.scroll_y -= @last_h if can_scroll?
    end
    
    def page_down
      self.scroll_y += @last_h if can_scroll?
    end
    
  private
    def draw_scrollbar x, y, h, total_height, offset
      return unless h < total_height
      Screen.style :widget => true do
        Screen.vertical_line x, y, h, ' '
      end
      
      bar_height = [h * h / total_height, 2].max
      bar_offset = offset * (h-bar_height) / (total_height - h)
      Screen.style :widget => true, :reverse => true do
        Screen.put_str x, y+bar_offset, Screen::UP_ARROW
        if bar_height > 2
          Screen.vertical_line x,  y+bar_offset+1, bar_height - 2, ' '
        end
        Screen.put_str x, y+bar_offset+bar_height-1, Screen::DOWN_ARROW
      end
    end
  end
end