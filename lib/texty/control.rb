module Texty
  class Control
    include Bindings
    
    def initialize(options = {})
      @top    = options[:top]
      @left   = options[:left]
      @bottom = options[:bottom]
      @right  = options[:right]
      @width  = options[:width]
      @height = options[:height]
      @left_padding   = options.fetch(:left_padding, 0)
      @right_padding  = options.fetch(:right_padding, 0)
      @top_padding    = options.fetch(:top_padding, 0)
      @bottom_padding = options.fetch(:bottom_padding, 0)
      @enabled = options.has_key?(:enabled) ? options[:enabled] : true
      @parent = nil
      raise ArgumentError.new("Invalid X bounds -- specify exactly 2 of left, right or width") unless valid_x_bounds?
      raise ArgumentError.new("Invalid Y bounds -- specify exactly 2 of top, bottom or height") unless valid_y_bounds?
    end
    
    attr_accessor :top, :left, :bottom, :right, :width, :height, 
      :left_padding, :right_padding, :top_padding, :bottom_padding, :parent
    
    def accepts_focus
      false
    end
    
    def draw
      draw_to_region(*bounds_coordinates)
    end

    def redraw
      draw
    end

    # Determines coordinates for bounding box based on parent size and
    # left/right/width/top/bottom/height parameters
    def bounds_coordinates
      pcx, pcy, pcw, pch = parent_bounds_coordinates

      if left && width
        cx = pcx + left
        cw = [width, pcw - left].min
      elsif left && right
        cx = pcx + left
        cw = pcw - left - right
      elsif width && right
        cx = pcx + pcw - right - width
        cw = pcw - cx - right
      end
      
      if top && height
        cy = pcy + top
        ch = [height, pch - top].min
      elsif top && bottom
        cy = pcy + top
        ch = pch - top - bottom
      elsif height && bottom
        cy = pcy + pch - bottom - height
        ch = pch - cy - bottom
      end

      [cx, cy, cw, ch]
    end

    # Bounds coordinates with space for padding subtracted
    def inner_bounds_coordinates
      ox, oy, ow, oh = bounds_coordinates
      [
        ox + left_padding,
        oy + top_padding,
        ow - left_padding - right_padding,
        oh - top_padding - bottom_padding
      ] 
    end

    private

    def parent_bounds_coordinates
      if parent
        parent.inner_bounds_coordinates
      else
        [0, 0, Screen.width, Screen.height]
      end
    end

    def valid_x_bounds?
      [left, right, width].compact.count == 2
    end

    def valid_y_bounds?
      [top, bottom, height].compact.count == 2
    end
  end
end
