dep_included? 'unicorn'

_cset(:unicorn_config)  { "#{shared_path}/config/unicorn.rb" }
_cset(:unicorn_log)     { "#{shared_path}/log/unicorn.log" }
_cset :unicorn_workers, 1

namespace :unicorn do

  desc "Initial Setup"
  task :setup, :roles => :app do
    run "mkdir -p #{shared_path}/config"
    template "unicorn/unicorn.rb.erb", unicorn_config
  end
  after "deploy:setup", "unicorn:setup"

  desc "Writes the unicorn part of the Procfile"
  task :procfile, :roles => :app do
    procfile_template = <<-EOF.gsub(/^\s+/, '')
      web: bundle exec unicorn -c <%= unicorn_config %> -E <%= rails_env %>
    EOF
    procfile = ERB.new(procfile_template, nil, '-')
    put procfile.result(binding), "#{shared_path}/Procfile.web"
  end
  after "foreman:pre_setup", "unicorn:procfile"
end
