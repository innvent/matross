dep_included? 'faye'
dep_included? 'thin'

_cset(:faye_config) { "#{shared_path}/config/faye_server.yml" }
_cset(:faye_ru)     { "#{shared_path}/config/faye.ru" }

namespace :faye do

  desc "Creates the faye_server.yml in shared path"
  task :setup, :roles => :app do
    run "mkdir -p #{shared_path}/config"
    template "faye/faye_server.yml.erb", faye_config
    template "faye/faye.ru.erb", faye_ru
  end
  after "deploy:setup", "faye:setup"

  desc "Updates the symlink for faye_server.yml for deployed release"
  task :symlink, :roles => :app do
    run "ln -nfs #{faye_config} #{release_path}/config/faye_server.yml"
  end
  after "bundle:install", "faye:symlink"

  desc "Writes the faye part of the Procfile"
  task :procfile, :roles => :faye do
    procfile_template = <<-EOF.gsub(/^\s+/, '')
      faye: bundle exec rackup  <%= faye_ru %> -s thin -E <%= rails_env %> -p <%= faye_port %>
    EOF
    procfile = ERB.new(procfile_template, nil, '-')
    put procfile.result(binding), "#{shared_path}/Procfile.faye"
  end
  after "foreman:pre_setup", "faye:procfile"
end
