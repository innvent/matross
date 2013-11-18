# matross

Matross is our collection of opinionated Capistrano recipes. We made a bunch of additions and customizations. Below we list the most relevant ones.

* **Foreman by default**: we use [`foreman`](http://ddollar.github.io/foreman/) to environment variables, init scripts, task definitions and more.
* **Custom foreman upstart template**: we also leverage `foreman`'s templates to build a custom upstart template that enables `console log`, allowing `logrotate` to work properly.

## Usage

Put `matross` in the `:development` group of your `Gemfile`:

```ruby
group :development do
  gem 'matross'
end
```

Run `bundle exec capify .` in the project root folder:

```bash
$ bundle exec capify .
```

Find a full example [down this `README`](#full-example).

### Overriding default templates

We have our opinions, but don't know everything. What works for us, may not fit your needs since each app is a unique snowflake. To take care of that, `matross` allows you to define your own templates instead of the built in ones. Look at the included ones in `lib/matross/templates` to see how we think things should go.

### Managing application daemons with Foreman

Foreman has freed us of the tedious task of writing `init` and Upstart scripts. Some of our `matross` recipes automatically add processes - such as the `unicorn` server - to the `Procfile`.

If you have an application Procfile with custom daemons defined, such as Rake task, they will be concatenated with all the processes defined in `matross`, resulting in one final `Procfile-matross` file that will be used to start your application and export init scrips.

You can specify the number of each instance defined in Procfile-matross using the `foreman_procs` variable.
Suppose you have a process called `dj` and want to export 3 instances of it:

```ruby
set :foreman_procs, {
    dj: 3
}
```

We also modified the default upstart template to log through upstart instead of just piping stdout and stderr into files. Goodbye nocturnal logexplosion. (Like all templates you can override it!).

If you have custom tasks that should also be started, simply list them in the `Procfile` in the root of your application. They will be appended to the recipe's task definitions (eg.: `unicorn`).

```
custom_task: bundle exec rake custom_task
```

If there are any environment variables that you want to use, just set them in a `.env` file in the root of your application. Please note that `RAILS_ENV` is properly set during `foreman` tasks.

```
CUSTOM_TASK_ENV=boost
```

## Recipes

### Foreman

Requires having [`foreman`](http://rubygems.org/gems/foreman) available in the application. As mentioned before, we use `foreman` in production to save us from generating upstart init scripts. As a bonus we get sane definition of environment variables.

Overwritable template: [`process.conf.erb`](lib/matross/templates/foreman/process.conf.erb)

> Variables

| Variable         | Default value                               | Description                                                    |
| ---              | ---                                         | ---                                                            |
| `:foreman_user`  | `{ user }` - The user defined in Capistrano | The user which should run the tasks defined in the `Procfile`  |
| `:foreman_bin`   | `'bundle exec foreman'`                     | The `foreman` command                                          |
| `:foreman_procs` | `{}` - Defaults to one per task definition  | Number of processes for each task definition in the `Procfile` |

> Tasks

| Task                | Description                                                                       |
| ---                 | ---                                                                               |
| `foreman:pre_setup` | Creates the `upstart` folder in the `shared_path`                                 |
| `foreman:setup`     | Merges all partial `Procfile`s and `.env`s, including the appropriate `RAILS_ENV` |
| `foreman:export`    | Export the task definitions as Upstart scripts                                    |
| `foreman:symlink`   | Symlink `.env-matross` and `Procfile-matross` to `current_path`                   |
| `foreman:log`       | Symlink Upstart logs to the log folder in  `shared_path`                          |
| `foreman:stop`      | Stop all of the application tasks                                                 |
| `foreman:restart`   | Restart or start all of the application tasks                                     |
| `foreman:remove`    | Remove all of the application tasks from Upstart                                  |

### Unicorn

Requires having [`unicorn`](http://unicorn.bogomips.org/index.html) available in the application. By loading our `unicorn` recipe, you get [our default configuration](lib/matross/templates/unicorn/unicorn.rb.erb).

Overwritable template: [`unicorn.rb.erb`](lib/matross/templates/unicorn/unicorn.rb.erb)
Procfile task: `web: bundle exec unicorn -c <%= unicorn_config %> -E <%= rails_env %>`

> Variables

| Variable           | Default value                        | Description                        |
| ---                | ---                                  | ---                                |
| `:unicorn_config`  | `"#{shared_path}/config/unicorn.rb"` | Location of the configuration file |
| `:unicorn_log`     | `"#{shared_path}/log/unicorn.log"`   | Location of unicorn log            |
| `:unicorn_workers` | `1`                                  | Number of unicorn workers          |

> Tasks

| Task               | Description                                                      |
| ---                | ---                                                              |
| `unicorn:setup`    | Creates the `unicorn.rb` configuration file in the `shared_path` |
| `unicorn:procfile` | Defines how `unicorn` should be run in a temporary `Procfile`    |


### Nginx

This recipes creates and configures the virtual_host for the application. [This virtual host] has some sane defaults, suitable for most of our deployments (non-SSL). The file is created at `/etc/nginx/sites-available` and symlinked to `/etc/nginx/sites-enabled`. These are the defaults for the Nginx installation in Ubuntu. You can take a look at [our general `nginx.conf`](https://github.com/innvent/parcelles/blob/puppet/puppet/modules/nginx/files/nginx.conf).

> Variables

| Variable                | Default value | Description                                           |
| ---                     | ---           | ---                                                   |
| `:htpasswd`             | None          | `htpasswd` user:password format                       |
| `:nginx_default_server` | `false`       | Sets the vhost for the specified stage as the default |



> Tasks

| Task           | Description                                       |
| ---            | ---                                               |
| `nginx:setup`  | Creates the virtual host file                     |
| `nginx:reload` | Reloads the Nginx configuration                   |
| `nginx:lock`   | Sets up the a basic http auth on the virtual host |
| `nginx:unlock` | Removes the basic http auth                       |


### MySQL

Requires having [`mysql2`](http://rubygems.org/gems/mysql2) available in the application. In our MySQL recipe we dynamically generate a `database.yml` based on the variables that should be set globally or per-stage.

Overwritable template: [`database.yml.erb`](lib/matross/templates/mysql/database.yml.erb)

> Variables

| Variable           | Default value                          | Description                                                                     |
| ---                | ---                                    | ---                                                                             |
| `:database_config` | `"#{shared_path}/config/database.yml"` | Location of the configuration file                                              |
| `:mysql_host`      | None                                   | MySQL host address                                                              |
| `:mysql_database`  | None                                   | MySQL database name. We automatically substitute dashes `-` for underscores `_` |
| `:mysql_user`      | None                                   | MySQL user                                                                      |
| `:mysql_passwd`    | None                                   | MySQL password                                                                  |

> Tasks

| Task                | Description                                                         |
| ---                 | ---                                                                 |
| `mysql:setup`       | Creates the `database.yml` in the `shared_path`                     |
| `mysql:symlink`     | Creates a symlink for the `database.yml` file in the `current_path` |
| `mysql:create`      | Creates the database if it hasn't been created                      |
| `mysql:schema_load` | Loads the schema if there are no tables in the DB                   |

## Mongoid

Requires having [`mongoid`](http://rubygems.org/gems/mongoid) available in the application. In our Mongoid recipe we dynamically generate a `mongoid.yml` based on the variables that should be set globally or per-stage.

Overwritable template: [`mongoid.yml.erb`](lib/matross/templates/mongoid/mongoid.yml.erb)

> Variables

| Variable          | Default value                         | Description                                |
| ---               | ---                                   | ---                                        |
| `:mongoid_config` | `"#{shared_path}/config/mongoid.yml"` | Location of the mongoid configuration file |
| `:mongo_hosts`    | None                                  | **List** of MongoDB hosts                  |
| `:mongo_database` | None                                  | MongoDB database name                      |
| `:mongo_user`     | None                                  | MongoDB user                               |
| `:mongo_passwd`   | None                                  | MongoDB password                           |

> Tasks

| Task                | Description                                                        |
| ---                 | ---                                                                |
| `mongoid:setup`     | Creates the `mongoid.yml` in the `shared_path`                     |
| `mongoid:symlink`   | Creates a symlink for the `mongoid.yml` file in the `current_path` |

### Delayed Job

Requires having [`delayed_job`](http://rubygems.org/gems/delayed_job) available in the application.

Procfile task: `dj: bundle exec rake jobs:work` or `dj_<%= queue_name %>: bundle exec rake jobs:work QUEUE=<%= queue_name %>`

> Variables

| Variable     | Default value | Description    |
| ---          | ---           | ---            |
| `:dj_queues` | None          | List of queues |


> Tasks

| Task                   | Description                                                       |
| ---                    | ---                                                               |
| `delayed_job:procfile` | Defines how `delayed_job` should be run in a temporary `Procfile` |


### Fog (AWS)

Requires having [`fog`](http://rubygems.org/gems/fog) available in the application. When we use `fog`, it is for interacting with Amazon services, once again very opinionated.

Overwritable template: [`fog_config.yml.erb`](lib/matross/templates/fog/fog_config.yml.erb)

The configuration generated may be used by other gems, such as [`carrierwave`](http://rubygems.org/gems/carrierwave). Here is an example of how we use it:

```ruby
# config/initializers/carrierwave.rb
CarrierWave.configure do |config|
  fog_config = YAML.load(File.read(File.join(Rails.root, 'config', 'fog_config.yml')))
  config.fog_credentials = {
    :provider               => 'AWS',
    :aws_access_key_id      => fog_config['aws_access_key_id'],
    :aws_secret_access_key  => fog_config['aws_secret_access_key'],
    :region                 => fog_config['region']
  }
  config.fog_directory  = fog_config['directory']
  config.fog_public     = fog_config['public']
end
```

> Variables

| Variable                     | Default value                            | Description                            |
| ---                          | ---                                      | ---                                    |
| `:fog_config`                | `"#{shared_path}/config/fog_config.yml"` | Location of the fog configuration file |
| `:fog_region`                | `'us-east-1'`                            | AWS Region                             |
| `:fog_public`                | `false`                                  | Bucket policy                          |
| `:fog_aws_access_key_id`     | None                                     | AWS Access Key Id                      |
| `:fog_aws_secret_access_key` | None                                     | AWS Secret Access Key                  |

> Tasks

| Task          | Description                                                           |
| ---           | ---                                                                   |
| `fog:setup`   | Creates the `fog_config.yml` in the `shared_path`                     |
| `fog:symlink` | Creates a symlink for the `fog_config.yml` file in the `current_path` |

### Faye

Requires having [`faye`](http://rubygems.org/gems/faye) available in the application.

Overwritable templates: [`faye.ru.erb`](lib/matross/templates/faye/faye.ru.erb) and [`faye_server.yml`](lib/matross/templates/faye/faye_server.yml)
Procfile task: `faye: bundle exec rackup  <%= faye_ru %> -s thin -E <%= rails_env %> -p <%= faye_port %>`

> Variables

| Variable       | Default value                             | Description                                          |
| ---            | ---                                       | ---                                                  |
| `:faye_config` | `"#{shared_path}/config/faye_config.yml"` | Location of the `faye` parameters configuration file |
| `:faye_ru`     | `"#{shared_path}/config/faye.ru"`         | Location of the `faye` configuration file            |
| `:faye_port`   | None                                      | Which port `faye` should listen on                   |

> Tasks

| Task           | Description                                                            |
| ---            | ---                                                                    |
| `faye:setup`   | Creates `faye_config.yml` and `faye.ru` in the `shared_path`           |
| `faye:symlink` | Creates a symlink for the `faye_config.yml` file in the `current_path` |


### Local Assets

This recipe overwrites the default assets precompilation by compiling them locally and then uploading the result to the server.

## Full Example

Below is a full example of how to use `matross` exhaustively. **Do note** that this would be an edge case as, for example, you don't normally run `mongoid` with `mysql`.

> `config/deploy.rb`

```ruby
set :stages, %w(production staging)
set :default_stage, 'staging'
require 'capistrano/ext/multistage'
require 'bundler/capistrano'
require 'matross'
load 'matross/local_assets'
load 'matross/nginx'
load 'matross/unicorn'
load 'matross/faye'
load 'matross/delayed_job'
load 'matross/fog'
load 'matross/mongoid'
load 'matross/mysql'
load 'matross/foreman'

set :application,           'awesome_application'
set :repository,            'git@github.com:innvent/awesome_application.git'
set :ssh_options,           { :forward_agent => true }
set :scm,                   :git
set :scm_verbose,           true
set :deploy_via,            :remote_cache
set :shared_children,       %w(public/system log tmp/pids public/uploads)
default_run_options[:pty]   = true

logger.level = Capistrano::Logger::DEBUG

after 'deploy:update', 'deploy:cleanup'
```

> `config/deploy/production.rb`

```ruby
set :user,                      'ubuntu'
set :group,                     'ubuntu'
set :use_sudo,                  false
set :branch,                    'master'
set :rails_env,                 'production'
set :deploy_to,                 "/home/#{user}/#{application}"
set :server_name,               'example.com'

set :mongo_hosts,               [ 'localhost' ]
set :mongo_database,            "#{application}_#{rails_env}"

set :mysql_host,                'localhost'
set :mysql_database,            "#{application}_#{rails_env}"
set :mysql_user,                "#{user}"
set :mysql_passwd,              ''

set :faye_port,                 '9292'
set :faye_local,                true

set :htpasswd,                  'admin:$apr1$twOdKBdh$okL.giy91y9LzXsD5swUb0'

set :dj_queues,                 [ 'queue1', 'queue2' ]

set :fog_aws_access_key_id,     'AKIACS5E2GU9NND0NMD4'
set :fog_aws_secret_access_key, 'rNB38h5Y4ysUM3r10F3oehrnp2ZaBcUPtiOnJyLn'
set :fog_directory,             'awesome_application_production'

set :foreman_procs,             { 'dj_queue1' => 2, 'dj_queue2' => 3 }

server '192.168.1.1', :app, :web, :dj, :faye, :db, :primary => true

set :default_environment, {
  'PATH' => "/home/#{user}/.rbenv/shims:/home/#{user}/.rbenv/bin:$PATH"
}
```

> `Capfile`

```ruby
load 'deploy'
load 'deploy/assets'
load 'config/deploy'
```
