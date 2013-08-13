set_default(:unicorn_config) { "#{shared_path}/config/unicorn.rb" }
set_default(:unicorn_workers, 1)
set_default(:unicorn_log) { "#{shared_path}/log/unicorn.log" }

namespace :unicorn do

  desc "Initial Setup"
  task :setup, :roles => [:app, :dj] do
    run "mkdir -p #{shared_path}/config"
    template "unicorn/unicorn.rb.erb", unicorn_config
  end
  after "deploy:setup", "unicorn:setup"

end
