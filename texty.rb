$: << "../missingno/"

puts $:

require 'ncurses'
require 'missingno'

module Texty
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
        p.call *args
      end
    end
    def_when /^trigger_(.+)$/, :trigger
  end
  
  class Application
    include Bindings
    
    attr_accessor :window
    attr_accessor :running
    
    def initialize options = {}
      @window = options[:window] || nil
    end
    
    def run
      begin
        Ncurses.initscr
        Ncurses.noecho
        Ncurses.curs_set 0
        
        raise "Colors not supported" unless Ncurses.has_colors?
        Ncurses.start_color
        Ncurses.use_default_colors if Ncurses.respond_to? :use_default_colors
        Ncurses.init_pair 1, Ncurses::COLOR_RED, Ncurses::COLOR_BLACK
        Ncurses.init_pair 2, Ncurses::COLOR_GREEN, Ncurses::COLOR_BLACK
        Ncurses.init_pair 3, Ncurses::COLOR_BLUE, Ncurses::COLOR_BLACK
        #Ncurses::keypad Ncurses::stdscr, true
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
      trigger_key_press key if key
    end
  end
  
  class Control
    def initialize options = {}
      @top = options[:top] || nil
      @left = options[:left] || nil
      @bottom = options[:bottom] || nil
      @right = options[:right] || nil
      @width = options[:width] || nil                        
      @height = options[:height] || nil
    end
    
    attr_accessor :top, :left, :bottom, :right, :width, :height
  end
  
  class Container < Control
    def initialize options = {}
      super
      @children = options[:children] || []
      @title = options[:title] || nil
    end
    
    attr_accessor :title
    
    def add_child child
      @children << child
    end
    
    def remove_child child
      @children.delete child
    end
    
    def clear_children
      @children.clear
    end
    
    def draw_to_region x, y, w, h
      unless @title.nil?
        draw_title_to_region x, y, w, 1
        draw_children_to_region x, y + 1, w, h - 2
      else
        draw_children_to_region x, y, w, h
      end
    end
  private
    def draw_title_to_region x, y, w, h
      Ncurses.move y, x
      Ncurses.attron Ncurses.COLOR_PAIR(3) | Ncurses::A_REVERSE
      Ncurses.addnstr " #{@title}".ljust(w), w
      Ncurses.attroff Ncurses.COLOR_PAIR(3) | Ncurses::A_REVERSE
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
          ch = h - top - c.bottom
        end
        
        #Ncurses.addstr "#{cx}, #{cy}, #{cw}, #{ch}"
        c.draw_to_region cx, cy, cw, ch
      end
    end
  end
  
  class Window < Container
    def initialize options = {}
      super
    end
    
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
  end
end