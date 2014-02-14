set :nginx_default_server, false

namespace :nginx do

  desc 'Setup application in nginx'
  task :setup do
    on roles :web do
      set :server_name, fetch(:server_name) { capture(:hostname, '-f') }

      template 'nginx/nginx_virtual_host_conf.erb',
        '/tmp/nginx_virtual_host_conf'
      sudo :mv, '/tmp/nginx_virtual_host_conf',
        "/etc/nginx/sites-available/#{fetch :application}"
      sudo :ln, '-nfs', "/etc/nginx/sites-available/#{fetch :application}",
        "/etc/nginx/sites-enabled"
    end
  end

  after 'deploy:published', 'nginx:setup'

  desc 'Reload nginx configuration'
  task :reload do
    on roles :web do
      sudo :service, 'nginx', 'reload'
    end
  end

  task :unlock do
    on roles :web do
      sudo :sed, '-i', "/auth_basic/d",
        "/etc/nginx/sites-available/#{fetch :application}"
    end
  end

  desc "Enable Basic Auth on the stage"
  task :lock do
    run_locally { execute :cap, "test", "nginx:unlock" }
    on roles :web do
      #invoke 'nginx:unlock'
      nginx_lock = "\\n        auth_basic \"Restricted\";\\n        auth_basic_user_file #{shared_path.to_s.gsub('/', '\\/')}\\/.htpasswd;"
      sudo :sed, '-i', "'s/.*location @#{fetch :application}.*/&#{nginx_lock}/'",
        "/etc/nginx/sites-available/#{fetch :application}"
      execute :echo, "#{fetch(:htpasswd).shellescape}" ">#{shared_path}/.htpasswd"
    end
  end

  after 'nginx:setup', 'nginx:reload'
  after 'nginx:lock', 'nginx:reload'
  after 'nginx:unlock', 'nginx:reload'
end
