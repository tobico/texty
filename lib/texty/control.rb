module Texty
  class Control
    include Bindings
    
    def initialize options = {}
      @top = options[:top] || nil
      @left = options[:left] || nil
      @bottom = options[:bottom] || nil
      @right = options[:right] || nil
      @width = options[:width] || nil                        
      @height = options[:height] || nil
      @enabled = options.has_key?(:enabled) ? options[:enabled] : true
    end
    
    attr_accessor :top, :left, :bottom, :right, :width, :height
    
    def accepts_focus
      false
    end
  end
end