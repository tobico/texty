module Texty
  module Bindings
    def bind key, &proc
      @bindings ||= Hash.new
      @bindings[key.to_sym] ||= []
      @bindings[key.to_sym] << proc
    end

    def unbind key, &proc
      return unless @bindings and @bindings.has_key?(key.to_sym)
    
      if proc.nil?
        @bindings.delete key.to_sym
      else
        @bindings[key.to_sym].delete proc
      end
    end
  
    def trigger key, *args
      return unless @bindings and @bindings.has_key?(key.to_sym)
      @bindings[key.to_sym].each do |p|
        p.call(*args) do |action|
          return :stop if action == :stop
        end
      end
    end
  end
end
