module Texty
  class Window < Container
    attr_accessor :title

    def initialize(options={})
      super options.merge(Texty::OPTIONS_FILL)
    end
    
    def redraw
      Screen.clear
      super
    end
  end
end
