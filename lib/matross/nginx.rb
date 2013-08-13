namespace :nginx do

  desc "Setup application in nginx"
  task :setup, :roles => :web do
    run "#{sudo} mkdir -p /etc/nginx/ssl"
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

end
