module Texty
  require 'missingno'
  
  USE_NCURSES = RUBY_VERSION =~ /1\.8\../
  
  OPTIONS_FILL = { :left => 0, :top => 0, :right => 0, :bottom => 0 }
  
  if USE_NCURSES
    autoload :Screen, 'texty/screen.ncurses'
  else
    autoload :Screen, 'texty/screen.curses'
  end
  
  autoload :Application, 'texty/application'
  autoload :Bindings, 'texty/bindings'
  autoload :Control, 'texty/control'
  autoload :Container, 'texty/container'
  autoload :Label, 'texty/label'
  autoload :List, 'texty/list'
  autoload :Scrollable, 'texty/scrollable'
  autoload :Window, 'texty/window'
end