module Texty
  module Bindings
    def bind key, &proc
      @bindings ||= Hash.new([])
      @bindings[key] << proc
    end
    def_when /^bind_(.+)$/, :bind
    def_when /^on_(.+)$/, :bind
  
    def unbind key, &proc
      return unless @bindings
    
      if proc.nil?
        @bindings.delete key
      else
        @bindings[key].delete proc
      end
    end
    def_when /^unbind_(.+)$/, :unbind
  
    def trigger key, *args
      return unless @bindings
      @bindings[key].each do |p|
        p.call *args do |action|
          return :stop if action == :stop
        end
      end
    end
    def_when /^trigger_(.+)$/, :trigger
  end
end