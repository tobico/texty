require 'ncurses'

module Texty
  class Screen
    def self.activate
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
        Ncurses.init_pair 8, Ncurses::COLOR_WHITE, Ncurses::COLOR_BLACK
        
        const_set 'UP_ARROW', Ncurses::ACS_UARROW
        const_set 'DOWN_ARROW', Ncurses::ACS_DARROW
      
        Ncurses.raw
        yield
      ensure
        Ncurses.curs_set 1
        Ncurses.endwin
      end        
    end
    
    def self.clear
      Ncurses.clear
    end
    
    def self.flush
      Ncurses.refresh
    end
    
    def self.put_str x, y, s
      if s.is_a? Fixnum
        Ncurses.mvaddch y, x, s
      else
        Ncurses.mvaddstr y, x, s
      end
    end
    
    def self.horizontal_line x, y, w, c = nil
      c = c ? c[0] : Ncurses::ACS_HLINE
      Ncurses.mvhline y, x, c, w
    end
    
    def self.vertical_line x, y, h, c = nil
      c = c ? c[0] : Ncurses::ACS_VLINE
      Ncurses.mvvline y, x, c, h
    end
    
    def self.draw_border x, y, w, h
      horizontal_line x+1,    y,      w-2
      horizontal_line x+1,    y+h-1,  w-2
      vertical_line   x,      y+1,    h-2
      vertical_line   x+w-1,  y+1,    h-2
      put_str         x,      y,      Ncurses::ACS_ULCORNER
      put_str         x+w-1,  y,      Ncurses::ACS_URCORNER
      put_str         x,      y+h-1,  Ncurses::ACS_LLCORNER
      put_str         x+w-1,  y+h-1,  Ncurses::ACS_LRCORNER
    end
    
    def self.print_line x, y, w, text
      put_str x, y, text[0...w]
    end
    
    def self.print_line_with_style x, y, w, style, text
      a = style_to_attr style
      Ncurses.attron a unless a == 0
      put_str x, y, text[0...w]
      Ncurses.attroff a unless a == 0
    end
  
    def self.style style
      attribute = style_to_attr style
      Ncurses.attron attribute if attribute > 0
      yield
      Ncurses.attroff attribute if attribute > 0
    end
  
    def self.width
      Ncurses.COLS
    end
    
    def self.height
      Ncurses.LINES
    end
  
    def self.get_key
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
      a |= Ncurses.COLOR_PAIR(color) if color > 0
      a |= Ncurses::A_REVERSE if reverse
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
  end
end