dep_included? 'mysql2'

_cset(:database_config) { "#{shared_path}/config/database.yml" }

namespace :db do

  desc "Creates the database.yml file in shared path"
  task :setup, :roles => [:app, :dj] do
    run "mkdir -p #{shared_path}/config"
    template "mysql/database.yml.erb", database_config
  end
  after "deploy:setup", "db:setup"

  desc "Updates the symlink for database.yml for the just deployed release"
  task :symlink, :roles => [:app, :dj] do
    run "ln -nfs #{database_config} #{current_path}/config/database_config"
  end
  before "deploy:restart", "db:symlink"

  desc "Creates the application database"
  task :create, :roles  => [:db] do
    sql = <<-EOF.gsub(/^\s+/, '')
      CREATE DATABASE IF NOT EXISTS #{mysql_database};
    EOF
    run "mysql --user=#{mysql_user} --password=#{mysql_passwd} --host=#{mysql_host} --execute=\"#{sql}\""
  end
end
