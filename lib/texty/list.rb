module Texty
  class List < Control
    def initialize options = {}
      super
      @items = []
      @selected_index = -1
      @scroll_y = 0
    end
    
    attr_accessor :items
    
    def add_item item
      @items << item
      self.selected_index = 0 if @items.length == 1
    end
    
    def clear
      @items.clear
      @selected_index = -1
    end
    
    def accepts_focus
      @enabled
    end
    
    def focus
      @has_focus = true
    end
    
    def blur
      @has_focus = false
    end
    
    attr_reader :selected_index
    def selected_index= index
      return unless @items.length
      index = 0 if index < 0
      index = @items.length - 1 if index >= @items.length
      @selected_index = index
      trigger_select @items[index]
    end
    
    attr_reader :scroll_y
    def scroll_y= value
      if value < 0
        @scroll_y = 0
      elsif value > @items.length - @last_h
        @scroll_y = @items.length - @last_h
      else
        @scroll_y = value
      end
      @selected_index = @scroll_y if @selected_index < @scroll_y
      @selected_index = @scroll_y + @last_h - 1 if @selected_index > @scroll_y + @last_h - 1
    end
    
    def page_up
      self.scroll_y -= @last_h if @last_h
    end
    
    def page_down
      self.scroll_y += @last_h if @last_h
    end
    
    def key_press key
      case key
        when :up
          self.selected_index -= 1
        when :down
          self.selected_index += 1
        when :pageup
          page_up
        when :pagedown
          page_down
      end
    end
    
    def draw_to_region x, y, w, h
      @last_h = h
      scroll_to_selection
      if @items.length > y
        draw_scrollbar x + w - 1, y, h, @items.length, @scroll_y
        w -= 1
      end
      cy = y
      (@scroll_y...@scroll_y+h).each do |i|
        break unless @items[i]
        item = @items[i]
        style = {}
        style[:selected] = @selected_index == i
        style[:active] = @has_focus
        style[:color] = item[:color] if item.include? :color
        Screen.print_line_with_style x, cy, w, style, item[:text].ljust(w)
        cy += 1
      end
    end
    
    def draw_scrollbar x, y, h, total_height, offset
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
    
  private
    def scroll_to_selection
      if @selected_index < @scroll_y
        @scroll_y = @selected_index
      end
      if @selected_index > @scroll_y + @last_h - 1
        @scroll_y = @selected_index - @last_h + 1
      end
    end
  end
end