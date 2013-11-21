dep_included? 'pg'

_cset(:database_config)             { "#{shared_path}/config/database.yml" }

namespace :postgresql do

  desc "Creates the database.yml file in shared path"
  task :setup, :roles => [:app, :dj] do
    run "mkdir -p #{shared_path}/config"
    template "postgresql/database.yml.erb", database_config
  end
  after "deploy:setup", "postgresql:setup"

  desc "Updates the symlink for database.yml for deployed release"
  task :symlink, :roles => [:app, :dj] do
    run "ln -nfs #{database_config} #{release_path}/config/database.yml"
  end
  after "bundle:install", "postgresql:symlink"
end
