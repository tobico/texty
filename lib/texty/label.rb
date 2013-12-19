module Texty
  class Label < Control
    def initialize(options={})
      super
      @text   = options.fetch(:text, 'Label')
      @style  = options.fetch(:style, nil)
    end
    
    attr :text, :style
    
    def draw_to_region(x, y, w, h)
      Screen.style(style) do
        Screen.put_str x, y, text[0, w]
      end
    end

    def text=(value)
      @text = value
      redraw
    end
  end
end
