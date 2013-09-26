$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "ism/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "ism"
  s.version     = Ism::VERSION
  s.authors     = ["Becky Carella"]
  s.email       = ["becarella@barkbox.com"]
  s.homepage    = "http://github.com/barkbox/ism"
  s.summary     = "Import social media."
  s.description = "Import social media."

  s.files = Dir["{app,config,db,lib}/**/*"] + ["MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 3.2.13"
  # s.add_dependency "jquery-rails"

  s.add_dependency 'rails', '~> 3.2.12'
  s.add_dependency 'instagram'
  
  s.add_development_dependency "sqlite3"
end
