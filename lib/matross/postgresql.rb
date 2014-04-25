dep_included? 'pg'

_cset(:database_config) { "#{shared_path}/config/database.yml" }
_cset(:postgresql_user) { user }

namespace :postgresql do

  desc 'Create the database.yml file in shared path. User is created if needed'
  task :setup, :roles => [:app, :dj] do
    run "mkdir -p #{shared_path}/config"
    template "postgresql/database.yml.erb", database_config
    user_count = capture(%W{ sudo -u postgres psql postgres -tAc
                             "SELECT 1 FROM pg_roles
                              WHERE rolname='#{postgresql_user}'" } * ' ').to_i
    if user_count == 0
      run "#{sudo} -u postgres createuser -d -r -s #{postgresql_user}"
    else
      logger.info 'User already created, skpping'
    end
  end
  after 'deploy:setup', 'postgresql:setup'

  desc 'Update the symlink for database.yml for deployed release'
  task :symlink, :roles => [:app, :dj] do
    run "ln -nfs #{database_config} #{release_path}/config/database.yml"
  end
  after 'bundle:install', 'postgresql:symlink'

  desc "Create the database and load the schema"
  task :create, :roles => :db do
    db_count = capture(%W{ #{sudo} -u postgres psql -lqt |
                           cut -d \\| -f 1 |
                           grep -w #{postgresql_database.gsub("-", "_")} |
                           wc -l } * ' ').to_i
    if db_count == 0
      run %W{ cd #{release_path} &&
              RAILS_ENV=#{rails_env.to_s.shellescape}
              bundle exec rake db:create db:schema:load } * ' '
    else
      logger.info 'DB is already configured, skipping'
    end
  end
  after 'postgresql:symlink', 'postgresql:create'
end
