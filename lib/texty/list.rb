module Texty
  class List < Control
    include Scrollable
    
    def initialize options = {}
      super
      @items = []
      @selected_index = -1
      @scroll_y = options[:scroll_y] || 0
      @scroll_height = 0
      bind(:scrolled_y) { reposition_selected }
    end
    
    attr_accessor :items
    
    def add_item item
      @items << item
      self.selected_index = 0 if @items.length == 1
      @scroll_height = @items.length
    end
    
    def clear
      @items.clear
      @selected_index = -1
      @scroll_height = 0
    end
    
    def accepts_focus?
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
      return if index == @selected_index
      index = 0 if index < 0
      index = @items.length - 1 if index >= @items.length
      @selected_index = index
      trigger_select @items[index] if @items[index]
    end
    
    def key_press key
      case key
        when :up
          self.selected_index -= 1
        when :down
          self.selected_index += 1
        when :pageup, :ctrl_b
          page_up
        when :pagedown, :ctrl_f
          page_down
      end
    end
    
    def draw_to_region x, y, w, h
      @last_h = h
      scroll_to_selection
      if @items.length > h
        draw_scrollbar x + w - 1, y, h, @items.length, scroll_y
        w -= 1
      end
      cy = y
      (@scroll_y...@scroll_y+h).each do |i|
        break unless @items[i]
        item = @items[i]
        style = {}
        style[:selected] = @selected_index == i
        style[:active] = @has_focus
        style[:color] = item[:color] || 0
        Screen.print_line_with_style x, cy, w, style, item[:text].ljust(w)
        cy += 1
      end
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
    
    def reposition_selected
      if @selected_index < @scroll_y
        @selected_index = @scroll_y
      end
      if @selected_index > @scroll_y + @last_h - 1
        @selected_index = @scroll_y + @last_h - 1 
      end
    end
  end
end
