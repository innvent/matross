dep_included? 'mongoid'

_cset(:mongoid_config) { "#{shared_path}/config/mongoid.yml" }

namespace :mongoid do

  desc "Creates the mongoid.yml file in shared path"
  task :setup, :roles => :app do
    run "mkdir -p #{shared_path}/config"
    template "mongoid/mongoid.yml.erb", mongoid_config
  end
  after "deploy:setup", "mongoid:setup"

  desc "Updates the symlink for mongoid.yml for deployed release"
  task :symlink, :roles => :app do
    run "ln -nfs #{mongoid_config} #{release_path}/config/mongoid_config.yml"
  end
  after "bundle:install", "mongoid:symlink"

end
