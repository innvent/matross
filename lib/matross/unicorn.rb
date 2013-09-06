_cset(:unicorn_config) { "#{shared_path}/config/unicorn.rb" }
_cset(:unicorn_log) { "#{shared_path}/log/unicorn.log" }
_cset, :unicorn_workers, 1

namespace :unicorn do

  desc "Initial Setup"
  task :setup, :roles => [:app, :dj] do
    run "mkdir -p #{shared_path}/config"
    template "unicorn/unicorn.rb.erb", unicorn_config
  end
  after "deploy:setup", "unicorn:setup"

end
