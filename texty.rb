$: << "../missingno/"

require 'ncurses'
require 'missingno'

module Texty
  OPTIONS_FILL = { :left => 0, :top => 0, :right => 0, :bottom => 0 }
  
  module Bindings
    def bind key, &proc
      @bindings ||= Hash.new([])
      @bindings[key] << proc
    end
    def_when /^bind_(.+)$/, :bind
    def_when /^on_(.+)$/, :bind
    
    def unbind key, &proc
      return unless @bindings
      
      if proc.nil?
        @bindings.delete key
      else
        @bindings[key].delete proc
      end
    end
    def_when /^unbind_(.+)$/, :unbind
    
    def trigger key, *args
      return unless @bindings
      @bindings[key].each do |p|
        p.call *args do |action|
          return :stop if action == :stop
        end
      end
    end
    def_when /^trigger_(.+)$/, :trigger
  end
  
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
  
  class Application
    include Bindings
    
    attr_accessor :running
    
    def initialize options = {}
      self.window = options[:window] || nil
    end
    
    attr_reader :window
    def window= window
      @window = window
      window.focus if window
    end
    
    def run
      begin
        Ncurses.initscr
        Ncurses.noecho
        Ncurses.curs_set 0
        
        raise "Colors not supported" unless Ncurses.has_colors?
        Ncurses.start_color
        Ncurses.use_default_colors if Ncurses.respond_to? :use_default_colors
        Ncurses.init_pair 1, Ncurses::COLOR_BLUE, -1
        Ncurses.init_pair 2, Ncurses::COLOR_RED, -1
        Ncurses.init_pair 3, Ncurses::COLOR_GREEN, -1
        Ncurses.init_pair 4, Ncurses::COLOR_RED, Ncurses::COLOR_WHITE
        Ncurses.init_pair 5, Ncurses::COLOR_GREEN, Ncurses::COLOR_WHITE
        Ncurses.init_pair 6, Ncurses::COLOR_RED, Ncurses::COLOR_BLUE
        Ncurses.init_pair 7, Ncurses::COLOR_GREEN, Ncurses::COLOR_BLUE
        Ncurses.raw
        
        @running = true
        @key_state = :normal
        while running
          main_loop
        end
      ensure
        Ncurses.curs_set 1
        Ncurses.endwin
      end
    end
    
    def terminate
      @running = false
    end
    
  private
    def escape_code_to_key code
      case code
        when /^1(.+)$/ then 
          n = $1.to_i
          n -= 1 if n > 6
          "f#{n}".to_sym
        when /^3/ then :delete
        when /^5/ then :pageup
        when /^6/ then :pagedown
      end
    end
  
    def escape_character_to_key char
      case char
        when ?A then :up
        when ?B then :down
        when ?C then :right
        when ?D then :left
        when ?H then :home
        when ?F then :end
        when ?Z then :backtab
        when (1..127) then
          "escape_#{char.chr}".to_sym
        else
          :unknown
      end
    end
  
    def character_to_key char
      case char
        when Ncurses::KEY_ENTER, 10, 13 then :enter
        when 27 then :esc
        when 9 then :tab
        when 127, 263 then :backspace
        when (1..7), (11..12), (14..26) then
          "ctrl_#{(char+96).chr}".to_sym
        when (1..127) then
          char.chr
        else
          :unknown
      end
    end
    
    def get_key
      char = Ncurses.getch
      
      #state machine to handle complex escape sequences
      @key_state ||= :normal
      if @key_state == :collect_escape_code
        if char == ?~
          key = escape_code_to_key @escape_code
          @key_state = :normal
        elsif (?0..?9).include? char
          key = nil
          @escape_code << char.chr
        else
          key = nil
        end
      elsif @key_state == :escape_sequence
        if (?0..?9).include? char
          @escape_code = char.chr
          @key_state = :collect_escape_code
          key = nil
        else
          key = escape_character_to_key char
          @key_state = :normal
        end
      elsif @key_state == :escaped
        key = character_to_key char        
        if key == "["
          @key_state = :escape_sequence
          key = nil
        else
          key = :escape if key == :esc
          @key_state = :normal
        end
      elsif @key_state == :normal
        key = character_to_key char
        if key == :esc
          @key_state = :escaped
          key = nil
        end
      end
      key
    end
    
    def main_loop
      @window.draw_to_screen
      
      key = get_key
      return terminate if (key == :ctrl_c)
      @window.key_press key if key
    end
  end
  
  class Control
    include Bindings
    
    def initialize options = {}
      @top = options[:top] || nil
      @left = options[:left] || nil
      @bottom = options[:bottom] || nil
      @right = options[:right] || nil
      @width = options[:width] || nil                        
      @height = options[:height] || nil
    end
    
    attr_accessor :top, :left, :bottom, :right, :width, :height
    
    def accepts_focus
      false
    end
  end
  
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
        Ncurses.attron Ncurses.COLOR_PAIR(1) if @has_focus
        Screen.draw_border x, y, w, h
        Screen.print_line x+1, y, w-2, @title if @title
        Ncurses.attroff Ncurses.COLOR_PAIR(1) if @has_focus
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
        
        #Ncurses.addstr "#{cx}, #{cy}, #{cw}, #{ch}"
        c.draw_to_region cx, cy, cw, ch
      end
    end
  end
  
  class Window < Container
    attr_accessor :title
    
    def draw_to_screen
      Ncurses.erase
      draw_to_region 0, 0, Ncurses.COLS, Ncurses.LINES
      Ncurses.refresh
    end
  end
  
  class Label < Control
    def initialize options = {}
      super
      @text = options[:text] || 'Label'
    end
    
    attr_accessor :text
    
    def draw_to_region x, y, w, h
      Ncurses.move y, x
      Ncurses.addnstr @text, w
    end
  end
  
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
      true
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
    
    def key_press key
      case key
        when :down
          self.selected_index += 1
        when :up
          self.selected_index -= 1
        when :pagedown
          self.scroll_y += @last_h if @last_h
        when :pageup
          self.scroll_y -= @last_h if @last_h
      end
    end
    
    def draw_to_region x, y, w, h
      @scroll_y = @selected_index if @selected_index < @scroll_y
      @scroll_y = @selected_index - h + 1 if @selected_index > @scroll_y + h - 1
      @last_h = h
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
  end
end