module Texty
  class Container < Control
    def initialize options = {}, &block
      super
      @children = options[:children] || []
      @title = options[:title] || nil
      @border = options[:border] || nil
    end
    
    attr_accessor :title
    
    def add_child child
      @children << child
      child
    end
    
    def remove_child child
      @children.delete child
    end
    
    def clear_children
      @children.clear
    end
    
    def draw_to_region x, y, w, h
      if @border == :single
        style = {}
        style[:color] = :blue if @has_focus
        Screen.style style do
          Screen.draw_border x, y, w, h
          Screen.print_line x+1, y, w-2, @title if @title
        end
        draw_children_to_region x+1, y + 1, w - 2, h - 2
      elsif @title
        draw_title_to_region x, y, w, 1
        draw_children_to_region x, y + 1, w, h - 1
      else
        draw_children_to_region x, y, w, h
      end
    end
    
    def accepts_focus
      @children.any? &:accepts_focus
    end
    
    attr_reader :focussed
    def focussed= focussed
      @focussed.blur if @focussed && @has_focus
      @focussed = focussed
      @focussed.focus if @focussed && @has_focus
    end
    
    def focus
      focus_first unless @focussed
      @has_focus = true
      @focussed.focus if @focussed
    end
    
    def blur
      @has_focus = false
      @focussed.blur if @focussed
    end
    
    def focus_first
      self.focussed = @children.find &:accepts_focus
    end
    
    def focus_next
      if @focussed.respond_to?(:focus_next) && @focussed.focus_next
        true
      else
        found_current = false
        next_focus = @children.find do |object|
          if object === @focussed
            found_current = true
            false
          else
            found_current && object.accepts_focus
          end
        end
        self.focussed = next_focus if next_focus
        next_focus
      end
    end
    
    def focus_last
      self.focussed = @children.reverse.find &:accepts_focus
    end
    
    def focus_prev
      if @focussed.respond_to?(:focus_prev) && @focussed.focus_prev
        true
      else
        found_current = false
        prev_focus = @children.reverse.find do |object|
          if object === @focussed
            found_current = true
            false
          else
            found_current && object.accepts_focus
          end
        end
        self.focussed = prev_focus if prev_focus
        prev_focus
      end
    end
    
    def key_press key
      unless trigger_key_press(key) == :stop
        case key
          when :tab
            focus_next or focus_first
          when :backtab
            focus_prev or focus_last
          else
            @focussed.key_press key if @focussed
        end
      end
    end
    
  private
    def draw_title_to_region x, y, w, h
      style = { :selected => true, :active => @has_focus }
      Screen.print_line_with_style x, y, w, style, " #{@title}".ljust(w)
    end
  
    def draw_children_to_region x, y, w, h
      @children.each do |c|
        if c.left && c.width
          cx = x + c.left
          cw = [c.width, w - c.left].min
        elsif c.left && c.right
          cx = x + c.left
          cw = w - c.left - c.right
        elsif c.width && c.right
          cx = x + w - c.right - c.width
          cw = w - cx - c.right
        end
        
        if c.top && c.height
          cy = y + c.top
          ch = [c.height, h - c.top].min
        elsif c.top && c.bottom
          cy = y + c.top
          ch = h - c.top - c.bottom
        elsif c.height && c.bottom
          cy = y + h - c.bottom - c.height
          ch = h - cy - c.bottom
        end
        
        c.draw_to_region cx, cy, cw, ch
      end
    end
  end
end