require 'capistrano'

if Capistrano::Configuration.instance
  Capistrano::Configuration.instance.load_paths << File.dirname(__FILE__)
  Capistrano::Configuration.instance.load "matross/base"
end
