module Ism
  class Engine < ::Rails::Engine
    isolate_namespace Ism
    
    initializer :ism do
      ActiveAdmin.application.load_paths.unshift Dir[File.dirname(__FILE__) + '/admin']
    end
    
  end
end
