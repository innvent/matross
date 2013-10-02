dep_included? 'foreman'

_cset(:foreman_user)  { user }
_cset :foreman_bin,   "bundle exec foreman"
_cset :foreman_procs, {}

namespace :foreman do

  desc "Pre-setup, creates the shared upstart folder"
  task :pre_setup do
    run "mkdir -p #{shared_path}/upstart"
  end
  before "foreman:setup", "foreman:pre_setup"

  desc "Merges all partial Procfiles and defines a specific dotenv"
  task :setup do
    run "cat $(test -f #{current_path}/Procfile && echo \"$_\") #{shared_path}/Procfile.* > #{shared_path}/Procfile-matross"
    run "rm #{shared_path}/Procfile.*"

    dotenv_template = <<-EOF.gsub(/^\s+/, '')
      RAILS_ENV=#{rails_env}
    EOF
    dotenv = ERB.new(dotenv_template, nil, '-')
    put dotenv.result(binding), "#{shared_path}/.env-matross-partial"
    run "cat $(test -f #{current_path}/.env && echo \"$_\") #{shared_path}/.env-matross-partial > #{shared_path}/.env-matross"
    run "rm #{shared_path}/.env-matross-partial"
  end
  before "foreman:export", "foreman:setup"

  desc "Export the Procfile to Ubuntu's upstart scripts"
  task :export, :roles => [:app, :dj] do
    matross_path = "#{shared_path}/matross"
    run "mkdir -p #{matross_path}"
    upload File.expand_path("../templates/foreman", __FILE__), matross_path,
           :via => :scp, :recursive => true

    proc_list = ""
    foreman_procs.each { |process, num|
      proc_list << ',' unless proc_list.empty?
      proc_list << "#{process}=#{num}"
    }
    proc_list = " -c #{proc_list}" unless proc_list.empty?

    run "cd #{current_path} && #{foreman_bin} export upstart #{shared_path}/upstart "\
      "-f #{shared_path}/Procfile-matross "\
      "-a #{application} "\
      "-u #{foreman_user} "\
      "-l #{shared_path}/log "\
      "-t #{matross_path}/foreman "\
      "-e #{shared_path}/.env-matross"\
      << proc_list
    run "cd #{shared_path}/upstart && #{sudo} cp * /etc/init/"
  end
  before "deploy:restart", "foreman:export"

  desc "Symlink configuration scripts"
  task :symlink, :roles => [:app, :dj], :except => { :no_release => true } do
    run "ln -nfs #{shared_path}/Procfile-matross #{current_path}/Procfile-matross"
    run "ln -nfs #{shared_path}/.env-matross #{current_path}/.env-matross"
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

end
