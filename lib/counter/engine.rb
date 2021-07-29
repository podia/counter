module Counter
  class Engine < ::Rails::Engine
    isolate_namespace Counter
  end
end
