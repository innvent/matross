dep_included? 'puma'

_cset(:puma_config)  { "#{shared_path}/config/puma.rb" }
_cset(:puma_log)     { "#{shared_path}/log/puma.log" }
_cset(:puma_workers) { capture("grep -c processor /proc/cpuinfo").to_i }
namespace :puma do

  desc "Initial Setup"
  task :setup, :roles => :app do
    run "mkdir -p #{shared_path}/config"
    template "puma/puma.rb.erb", puma_config
  end
  after "deploy:setup", "puma:setup"

  desc "Writes the puma part of the Procfile"
  task :procfile, :roles => :app do
    procfile_template = <<-EOF.gsub(/^\s+/, '')
      web: bundle exec puma -C <%= puma_config %> -e <%= rails_env %>
    EOF
    procfile = ERB.new(procfile_template, nil, '-')
    put procfile.result(binding), "#{shared_path}/Procfile.web"
  end
  after "foreman:pre_setup", "puma:procfile"
end
