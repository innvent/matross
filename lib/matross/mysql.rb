dep_included? 'mysql2'

_cset(:database_config)             { "#{shared_path}/config/database.yml" }
_cset(:mysql_backup_script)         { "#{shared_path}/matross/mysql_backup.sh" }
_cset :mysql_backup_cron_schedule,  '30 3 * * *'

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

  namespace :backup do

    desc "Updates the crontab"
    task :setup, :roles => :db do
      template "mysql/backup.sh.erb", mysql_backup_script

      comment_open  = '# Begin Matross generated task for MySQL Backup'
      comment_close = '# End Matross generated task for MySQL Backup'

      mysql_command    = "#{mysql_backup_script} 2>&1 >> #{shared_path}/log/mysql_backup.log"
      mysql_cron_entry = "#{mysql_backup_cron_schedule} #{mysql_backup_cron_command}"
      mysql_cron       = [comment_open, mysql_cron_entry, comment_close].compact.join("\n")

      current_crontab = ''
      begin
        current_crontab = run("crontab -l -u #{user} 2> /dev/null")
      rescue Capistrano::CommandError
      end
      contains_open_comment  = current_crontab =~ /^#{comment_open}\s*$/
      contains_close_comment = current_crontab =~ /^#{comment_close}\s*$/

      # If an existing identier block is found, replace it with the new cron entries
      if contains_open_comment && contains_close_comment
        current_crontab.gsub(/^#{comment_open}\s*$.+^#{comment_close}\s*$/m, mysql_cron.chomp)
      else  # Otherwise, append the new cron entries after any existing ones
        [read_crontab, mysql_cron].join("\n\n")
      end.gsub(/\n{3,}/, "\n\n")  # More than two newlines becomes just two.

    end
  end
end
