$: << "../missingno/"

require 'ncurses'
require 'missingno'

module Texty
  OPTIONS_FILL = { :left => 0, :top => 0, :right => 0, :bottom => 0 }
  
  autoload :Application, 'texty/application'
  autoload :Bindings, 'texty/bindings'
  autoload :Control, 'texty/control'
  autoload :Container, 'texty/container'
  autoload :Label, 'texty/label'
  autoload :List, 'texty/list'
  autoload :Screen, 'texty/screen'
  autoload :Window, 'texty/window'
end