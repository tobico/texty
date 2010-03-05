# encoding: UTF-8

require 'curses'

module Texty
  class Screen
    HAS_UNICODE = not (RUBY_VERSION =~ /1\.8\../)
    HORIZONTAL_LINE = HAS_UNICODE ? '─' : '-'
    VERTICAL_LINE = HAS_UNICODE ? '│' : '|'
    TL_CORNER = HAS_UNICODE ? '┌' : '+'
    TR_CORNER = HAS_UNICODE ? '┐' : '+'
    BL_CORNER = HAS_UNICODE ? '└' : '+'
    BR_CORNER = HAS_UNICODE ? '┘' : '+'
    UP_ARROW = HAS_UNICODE ? '↑' : '^'
    DOWN_ARROW = HAS_UNICODE ? '↓' : 'v'
    LEFT_ARROW = HAS_UNICODE ? '←' : '<'
    RIGHT_ARROW = HAS_UNICODE ? '→' : '>'
    
    def self.activate
      begin
        Curses.init_screen
        Curses.noecho
        Curses.curs_set 0
      
        raise "Colors not supported" unless Curses.has_colors?
        Curses.start_color
        Curses.use_default_colors if Curses.respond_to? :use_default_colors
        Curses.init_pair 1, Curses::COLOR_BLUE, 0
        Curses.init_pair 2, Curses::COLOR_RED, 0
        Curses.init_pair 3, Curses::COLOR_GREEN, 0
        Curses.init_pair 4, Curses::COLOR_RED, Curses::COLOR_WHITE
        Curses.init_pair 5, Curses::COLOR_GREEN, Curses::COLOR_WHITE
        Curses.init_pair 6, Curses::COLOR_RED, Curses::COLOR_BLUE
        Curses.init_pair 7, Curses::COLOR_GREEN, Curses::COLOR_BLUE
        Curses.init_pair 8, Curses::COLOR_WHITE, Curses::COLOR_BLACK
      
        Curses.raw
        
        yield
      ensure
        Curses.curs_set 1
        Curses.close_screen
      end
    end
    
    def self.clear
      Curses.clear
    end
    
    def self.flush
      Curses.refresh
    end
    
    def self.put_char x, y, c
      Curses.setpos y, x
      Curses.addch c
    end
    
    def self.put_str x, y, s
      Curses.setpos y, x
      Curses.addstr s
    end
    
    def self.horizontal_line x, y, w, c = HORIZONTAL_LINE
      Curses.setpos y, x
      Curses.addstr c * w
    end
    
    def self.vertical_line x, y, h, c = VERTICAL_LINE
      (y...y+h).each do |cy|
        put_str x, cy, c
      end
    end
    
    def self.draw_border x, y, w, h
      horizontal_line x+1,    y,      w-2
      horizontal_line x+1,    y+h-1,  w-2
      vertical_line   x,      y+1,    h-2
      vertical_line   x+w-1,  y+1,    h-2
      put_str         x,      y,      TL_CORNER
      put_str         x+w-1,  y,      TR_CORNER
      put_str         x,      y+h-1,  BL_CORNER
      put_str         x+w-1,  y+h-1,  BR_CORNER
    end
    
    def self.print_line x, y, w, text
      put_str x, y, text[0...w]
    end
    
    def self.print_line_with_style x, y, w, style, text
      a = style_to_attr style
      Curses.attron a unless a == 0
      put_str x, y, text[0...w]
      Curses.attroff a unless a == 0
    end
  
    def self.style style
      attribute = style_to_attr style
      Curses.attron attribute if attribute > 0
      yield
      Curses.attroff attribute if attribute > 0
    end
  
    def self.width
      Curses.cols
    end
    
    def self.height
      Curses.lines
    end
  
    def self.get_key
      char = Curses.getch
    
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
  
  private
    def self.style_to_attr style
      color = 0
      reverse = false
      if style[:selected]
        if style[:active]
          if style[:color] == :red
            color, reverse = 2, true
          elsif style[:color] == :green
            color, reverse = 3, true
          else
            color, reverse = 1, true
          end
        else
          if style[:color] == :red
            color = 4
          elsif style[:color] == :green
            color = 5
          else
            reverse = true
          end
        end
      elsif style[:widget]
        color = 8
      else
        if style[:color] == :red
          color = 2
        elsif style[:color] == :green
          color = 3
        elsif style[:color] == :blue
          color = 1
        end
      end
      if style[:reverse]
        reverse = !reverse
      end
      a = 0
      a |= Curses.color_pair(color) if color > 0
      a |= Curses::A_REVERSE if reverse
      a
    end
  
    def self.escape_code_to_key code
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

    def self.escape_character_to_key char
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

    def self.character_to_key char
      case char
        when Curses::KEY_ENTER, 10, 13 then :enter
        when 27 then :esc
        when 9 then :tab
        when 127, 263 then :backspace
        when (1..7), (11..12), (14..26) then
          "ctrl_#{(char+96).chr}".to_sym
        when (1..127) then
          char.chr
        else
          char
      end
    end
  end
end