dep_included? 'mysql2'

_cset(:database_config) { "#{shared_path}/config/database.yml" }

namespace :mysql do

  desc "Creates the database.yml file in shared path"
  task :setup, :roles => [:app, :dj] do
    run "mkdir -p #{shared_path}/config"
    template "mysql/database.yml.erb", database_config
  end
  after "deploy:setup", "mysql:setup"

  desc "Updates the symlink for database.yml for deployed release"
  task :symlink, :roles => [:app, :dj] do
    run "ln -nfs #{database_config} #{release_path}/config/database.yml"
  end
  after "bundle:install", "mysql:symlink"

  desc "Creates the application database"
  task :create, :roles  => [:db] do
    sql = <<-EOF.gsub(/^\s+/, '')
      CREATE DATABASE IF NOT EXISTS #{mysql_database.gsub("-", "_")};
    EOF
    run "mysql --user=#{mysql_user} --password=#{mysql_passwd} --host=#{mysql_host} --execute=\"#{sql}\""
  end
  after "mysql:setup", "mysql:create"

  desc "Loads the application schema into the database"
  task :schema_load, :roles => [:db] do
    sql = <<-EOF.gsub(/^\s+/, '')
      SELECT count(*) FROM information_schema.TABLES WHERE (TABLE_SCHEMA = '#{mysql_database.gsub("-", "_")}');
    EOF
    table_count = capture("mysql --batch --skip-column-names "\
                          "--user=#{mysql_user} "\
                          "--password=#{mysql_passwd} "\
                          "--host=#{mysql_host} "\
                          "--execute=\"#{sql}\"").to_i
    run "cd #{release_path} &&"\
      "RAILS_ENV=#{rails_env.to_s.shellescape} bundle exec rake db:schema:load" if table_count == 0
  end
  after "mysql:symlink", "mysql:schema_load"

  namespace :dump do
    desc "Dumps the application database"
    task :do, :roles => [:db], :except => { :no_release => true } do
      run "mkdir -p #{shared_path}/dumps"
      mysql_passwd_str = "-p#{mysql_passwd}" unless mysql_passwd.empty?
      run %W{cd #{shared_path}/dumps && mysqldump -h#{mysql_host}
        -u#{mysql_user} #{mysql_passwd_str} --quote-names --create-options
        #{mysql_database} | gzip >
        "$(date +'#{mysql_database}_\%Y\%m\%d\%H\%M.sql.gz')"} * ' '
    end

    desc "Downloads a copy of the last generated database dump"
    task :get, :roles => [:db], :except => { :no_release => true } do
      run_locally "mkdir -p dumps"
      most_recent_bkp = capture(%W{find #{shared_path} -type f -name
          '#{mysql_database}_*.sql.gz'} * ' ').split.sort.last
      abort "No dump found. Run mysql:dump:do." if most_recent_bkp.nil?
      download "#{most_recent_bkp}", "dumps/"
      run_locally "gzip -d dumps/#{File.basename(most_recent_bkp)}"
    end

    desc "Applies the latest dump stored in 'dumps'"
    task :apply, :roles => [:db], :except => { :no_release => true } do
    end
  end
end
