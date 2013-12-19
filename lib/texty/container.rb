module Texty
  class Container < Control
    def initialize options = {}, &block
      super
      @children = options[:children] || []
      @title = options[:title] || nil
      @border = options[:border] || nil
      @top_padding = 1 if @title
      if @border
        @top_padding = 1
        @left_padding = 1
        @bottom_padding = 1
        @right_padding = 1
      end
    end
    
    attr :title, :children, :focused
    
    def add_child(child)
      @children << child
      child.parent = self
      focus_first unless focused
      child
    end
    
    def remove_child(child)
      @children.delete child
      child.parent = nil
      child
    end
    
    def clear_children
      @children.clear
    end
    
    def draw_to_region(x, y, w, h)
      if @border == :single
        style = {}
        style[:color] = :blue if @has_focus
        screen.style style do
          screen.draw_border x, y, w, h
          screen.print_line x+1, y, w-2, @title if @title
        end
      elsif @title
        draw_title_to_region x, y, w, 1
      end
      children.each(&:draw)
    end
    
    def accepts_focus?
      @children.any?(&:accepts_focus?)
    end
    
    def focused= focused
      @focused.blur if @focused && @has_focus
      @focused = focused
      @focused.focus if @focused && @has_focus
    end
    
    def focus
      focus_first unless @focused
      @has_focus = true
      @focused.focus if @focused
    end
    
    def blur
      @has_focus = false
      @focused.blur if @focused
    end
    
    def focus_first
      self.focused = @children.find(&:accepts_focus?)
    end
    
    def focus_next
      if @focused.respond_to?(:focus_next) && @focused.focus_next
        true
      else
        found_current = false
        next_focus = @children.find do |object|
          if object === @focused
            found_current = true
            false
          else
            found_current && object.accepts_focus
          end
        end
        self.focused = next_focus if next_focus
        next_focus
      end
    end
    
    def focus_last
      self.focused = @children.reverse.find(&:accepts_focus)
    end
    
    def focus_prev
      if @focused.respond_to?(:focus_prev) && @focused.focus_prev
        true
      else
        found_current = false
        prev_focus = @children.reverse.find do |object|
          if object === @focused
            found_current = true
            false
          else
            found_current && object.accepts_focus
          end
        end
        self.focused = prev_focus if prev_focus
        prev_focus
      end
    end
    
    def key_press(key)
      unless trigger(:key_press, key) == :stop
        case key
          when :tab
            focus_next or focus_first
          when :backtab
            focus_prev or focus_last
          else
            @focused.key_press key if @focused
        end
      end
    end
    
  private
    def draw_title_to_region(x, y, w, h)
      style = { :selected => true, :active => @has_focus }
      screen.print_line_with_style x, y, w, style, " #{@title}".ljust(w)
    end
  end
end
