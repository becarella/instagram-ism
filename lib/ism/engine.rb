module Ism
  class Engine < ::Rails::Engine
    isolate_namespace Ism
    
    initializer :ism do
      ActiveAdmin.application.load_paths.unshift Dir[File.dirname(__FILE__) + '/admin']
    end
    
    # http://pivotallabs.com/leave-your-migrations-in-your-rails-engines/
    initializer :append_migrations do |app|
      unless app.root.to_s.match root.to_s
        app.config.paths["db/migrate"] += config.paths["db/migrate"].expanded
      end
    end
    
  end
end
