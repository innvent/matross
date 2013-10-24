dep_included? 'faye'

_cset(:faye_config) { "#{shared_path}/config/faye_server.yml" }

namespace :faye do

  desc "Creates the faye_server.yml in shared path"
  task :setup, :roles => :app do
    run "mkdir -p #{shared_path}/config"
    template "faye/faye_server.yml.erb", faye_config
  end
  after "deploy:setup", "faye:setup"

  desc "Updates the symlink for faye_server.yml for deployed release"
  task :symlink, :roles => :app do
    run "ln -nfs #{faye_config} #{release_path}/config/faye_server.yml"
  end
  after "bundle:install", "faye:symlink"

end
