namespace :nginx do

  desc "Setup application in nginx"
  task :setup, :roles => :web do
    template "nginx/nginx_virtual_host_conf.erb", "/tmp/#{application}"
    run "#{sudo} mv /tmp/#{application} /etc/nginx/sites-available/#{application}"
    run "#{sudo} ln -fs /etc/nginx/sites-available/#{application} /etc/nginx/sites-enabled/#{application}"
    run "mkdir -p #{shared_path}/sockets"
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
  end

  task :unlock, :roles => :web do
    run "#{sudo} sed -i /auth_basic/d /etc/nginx/sites-available/#{application}"
  end
end
