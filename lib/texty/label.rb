module Texty
  class Label < Control
    def initialize options = {}
      super
      @text = options[:text] || 'Label'
    end
    
    attr_accessor :text
    
    def draw_to_region x, y, w, h
      Screen.put_str x, y, @text[0...w]
    end
  end
end