set_default(:foreman_bin) { "bundle exec foreman" }
set_default(:foreman_user) { user }

namespace :foreman do
  desc "Initial Setup"
  task :setup, :roles => [:app, :dj] do
    run "mkdir -p #{shared_path}/upstart"
    app_procfile
    run "cat #{shared_path}/Procfile.* > #{shared_path}/Procfile"
    run "rm #{shared_path}/Procfile.*"
  end
  before "foreman:export", "foreman:setup"

  desc "Export the Procfile to Ubuntu's upstart scripts"
  task :export, :roles => [:app, :dj] do
    run "cd #{current_path} && #{foreman_bin} export upstart #{shared_path}/upstart "\
      "-f #{current_path}/Procfile "\
      "-a #{application} "\
      "-u #{foreman_user} "\
      "-l #{shared_path}/log "
    run "cd #{shared_path}/upstart && #{sudo} cp * /etc/init/"
  end
  before "deploy:restart", "foreman:export"

  desc "Symlink configuration scripts"
  task :symlink, :roles => [:app, :dj], :except => { :no_release => true } do
    run "ln -nfs #{shared_path}/Procfile #{release_path}/Procfile"
  end
  after "foreman:setup", "foreman:symlink"

  desc "Restart services"
  task :restart, :roles => [:app, :dj] do
    run "#{sudo} start #{application} || #{sudo} restart #{application}"
  end
  after "deploy:restart", "foreman:restart"

  desc "Remove upstart scripts"
  task :remove, :roles => [:app, :dj] do
    run "cd #{shared_path}/upstart && rm -f Procfile*"
    run "cd /etc/init/ && #{sudo} rm #{application}*"
  end

  task :app_procfile, :roles => :app do
    procfile_template = <<-EOF
web:  bundle exec unicorn -c <%= unicorn_config %> -E <%= rails_env %> 
EOF
    procfile = ERB.new(procfile_template, nil, '-')
    put procfile.result(binding), "#{shared_path}/Procfile.app"
  end

end
