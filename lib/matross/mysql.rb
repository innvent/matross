dep_included? 'mysql2'

_cset(:database_config)             { "#{shared_path}/config/database.yml" }
_cset(:mysql_backup_script)         { "#{shared_path}/matross/mysql_backup.sh" }
_cset :mysql_backup_cron_schedule,  '30 3 * * *'

namespace :mysql do

  desc "Create the database.yml file in shared path"
  task :setup, :roles => [:app, :dj] do
    run "mkdir -p #{shared_path}/config"
    template "mysql/database.yml.erb", database_config
  end
  after "deploy:setup", "mysql:setup"

  desc "Update the symlink for database.yml for deployed release"
  task :symlink, :roles => [:app, :dj] do
    run "ln -nfs #{database_config} #{release_path}/config/database.yml"
  end
  after "bundle:install", "mysql:symlink"

  desc "Create the application database"
  task :create, :roles  => :db do
    sql = <<-EOF.gsub(/^\s+/, '')
      CREATE DATABASE IF NOT EXISTS #{mysql_database.gsub("-", "_")};
    EOF
    run %W{mysql --user=#{mysql_user}
             #{'--password=' + mysql_passwd unless mysql_passwd.empty?}
             --host=#{mysql_host}
             --execute="#{sql}"} * ' '
  end
  after "mysql:setup", "mysql:create"

  desc "Load the application schema into the database"
  task :schema_load, :roles => :db do
    sql = <<-EOF.gsub(/^\s+/, '')
      SELECT count(*) FROM information_schema.TABLES WHERE (TABLE_SCHEMA = '#{mysql_database.gsub("-", "_")}');
    EOF
    table_count = capture(%W{mysql --batch --skip-column-names
                              --user=#{mysql_user}
                              #{'--password=' + mysql_passwd unless mysql_passwd.empty?}
                              --host=#{mysql_host}
                              --execute="#{sql}"} * ' ').to_i
    run %W{cd #{release_path} &&
           RAILS_ENV=#{rails_env.to_s.shellescape} bundle exec rake db:schema:load
        } * ' ' if table_count == 0
  end
  after "mysql:symlink", "mysql:schema_load"

  namespace :backup do

    # This routine is heavily inspired by whenever's approach
    # https://github.com/javan/whenever
    desc "Update the crontab with the backup entry"
    task :setup, :roles => :db do
      template "mysql/backup.sh.erb", mysql_backup_script
      run "chmod +x #{mysql_backup_script}"

      comment_open  = '# Begin Matross generated task for MySQL Backup'
      comment_close = '# End Matross generated task for MySQL Backup'

      cron_command = "#{mysql_backup_script} >> #{shared_path}/log/mysql_backup.log 2>&1"
      cron_entry   = "#{mysql_backup_cron_schedule} #{cron_command}"
      cron         = [comment_open, cron_entry, comment_close].compact.join("\n")

      current_crontab = ''
      begin
        # Some cron implementations require all non-comment lines to be
        # newline-terminated. Strip all newlines and replace with the default
        # platform record seperator ($/)
        current_crontab = capture("crontab -l -u #{user} 2> /dev/null").gsub!(/\s+$/, $/)
      rescue Capistrano::CommandError
        logger.debug 'The user has no crontab'
      end
      contains_open_comment  = current_crontab =~ /^#{comment_open}\s*$/
      contains_close_comment = current_crontab =~ /^#{comment_close}\s*$/

      # If an existing identier block is found, replace it with the new cron entries
      if contains_open_comment && contains_close_comment
        updated_crontab = current_crontab.gsub(/^#{comment_open}\s*$.+^#{comment_close}\s*$/m, cron.chomp)
      else  # Otherwise, append the new cron entries after any existing ones
        updated_crontab = current_crontab.empty? ? cron : [current_crontab, cron].join("\n")
      end.gsub(/\n{2,}/, "\n")  # More than one newline becomes just one.

      temp_crontab_file = "/tmp/matross_#{user}_crontab"
      put updated_crontab, temp_crontab_file
      run "crontab -u #{user} #{temp_crontab_file}"
      run "rm #{temp_crontab_file}"
    end
  end

  namespace :dump do

    desc "Dump the application database"
    task :do, :roles => :db, :except => { :no_release => true } do
      run "mkdir -p #{shared_path}/dumps"
      run %W{cd #{shared_path}/dumps &&
             mysqldump --quote-names --create-options
              --user=#{mysql_user}
              #{'--password=' + mysql_passwd unless mysql_passwd.empty?}
              --host=#{mysql_host}
              #{mysql_database.gsub("-", "_")} |
             gzip > "$(date +'#{mysql_database}_\%Y\%m\%d\%H\%M.sql.gz')"} * ' '
    end

    desc "Download a copy of the last generated database dump"
    task :get, :roles => :db, :except => { :no_release => true } do
      run_locally "mkdir -p dumps"
      most_recent_bkp = capture(%W{find #{shared_path} -type f -name
                                    '#{mysql_database}_*.sql.gz'} * ' '
                               ).split.sort.last
      abort 'No dump found. Run mysql:dump:do' if most_recent_bkp.nil?

      download most_recent_bkp, "dumps", :via => :scp
      run_locally "gzip -d dumps/#{File.basename(most_recent_bkp)}"
    end

    desc "Apply the latest dump generated stored in 'dumps' locally"
    task :apply, :roles => :db, :except => { :no_release => true } do
      most_recent_bkp = %x[find dumps -type f -name\
                            '#{mysql_database}_*.sql'].split.sort.last
      abort "No dump found. Run mysql:dump:get." if most_recent_bkp.nil?

      db_config = YAML.load(File.read('config/database.yml'))['development']
      run_locally %W{mysql --user=#{db_config['username']}
                      --host=#{db_config['host']}
                      #{'--password=' + db_config['password'] unless db_config['password'].nil?}
                      #{db_config['database']} < #{most_recent_bkp}} * ' '
    end

    desc "Upload a copy of the last generated database dump"
    task :post, :roles => :db, :except => { :no_release => true } do
      run "mkdir -p #{shared_path}/dumps"
      most_recent_bkp = %x[find dumps -type f -name '*.sql'].split.sort.last
      abort 'No dump found. Run mysql:dump:get' if most_recent_bkp.nil?

      run_locally "gzip -k #{most_recent_bkp}"
      zipped_bkp = most_recent_bkp + '.gz'

      upload zipped_bkp, "#{shared_path}/dumps", :via => :scp
      run_locally "rm #{zipped_bkp}"
    end

    desc "Apply the latest uploaded dump in the remote server"
    task :apply_remotely, :roles => :db, :except => { :no_release => true } do
      most_recent_bkp = capture(%W{find #{shared_path} -type f -name '*.sql.gz'} * ' ').split.sort.last
      abort 'No dump found. Run mysql:dump:post' if most_recent_bkp.nil?

      db_config = YAML.load(capture("cat #{shared_path}/config/database.yml"))[rails_env]
      run %W{zcat #{most_recent_bkp} | mysql --user=#{db_config['username']}
              --host=#{db_config['host']}
              #{'--password=' + db_config['password'] unless db_config['password'].nil?}
              #{db_config['database']}} * ' '
    end
    before "mysql:dump:apply_remotely", "foreman:stop"
    after  "mysql:dump:apply_remotely", "foreman:restart"

  end
end
