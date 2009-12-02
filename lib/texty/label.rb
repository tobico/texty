module Texty
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
end