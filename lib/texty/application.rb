module Texty
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
        Ncurses.init_pair 8, Ncurses::COLOR_WHITE, Ncurses::COLOR_BLACK
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
end