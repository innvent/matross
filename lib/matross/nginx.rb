_cset :nginx_default_server, false

namespace :nginx do

  desc "Setup application in nginx"
  task :setup, :roles => :web do
    template "nginx/nginx_virtual_host_conf.erb", "/tmp/nginx_virtual_host_conf"
    run "#{sudo} mv /nginx_virtual_host_conf /etc/nginx/sites-available/#{application}"
    run "#{sudo} ln -fs /etc/nginx/sites-available/#{application} /etc/nginx/sites-enabled/#{application}"
  end
  after "deploy:setup", "nginx:setup"

  desc "Reload nginx configuration"
  task :reload, :roles => :web do
    run "#{sudo} /etc/init.d/nginx reload"
  end
  after "deploy:setup", "nginx:reload"
  after "nginx:lock",   "nginx:reload"
  after "nginx:unlock", "nginx:reload"

  desc "Enable Basic Auth on the stage"
  task :lock, :roles => :web do
    run "#{sudo} sed -i /auth_basic/d /etc/nginx/sites-available/#{application}"
    nginx_lock = "        auth_basic \"Restricted\";\n        auth_basic_user_file #{shared_path.gsub('/', '\\/')}\\/.htpasswd;"
    run "#{sudo} sed -i 's/.*location @#{application}.*/&\n#{nginx_lock}/' /etc/nginx/sites-available/#{application}"
    run "echo #{htpasswd.shellescape} > #{shared_path}/.htpasswd"
  end

  task :unlock, :roles => :web do
    run "#{sudo} sed -i /auth_basic/d /etc/nginx/sites-available/#{application}"
  end
end
