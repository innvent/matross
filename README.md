# matross

## Usage

Put matross in the `:development` group of your `Gemfile`:

```ruby
group :development do
  gem 'matross'
end
```

Run `bundle exec capify .` in the project root folder:

```bash
$ bundle exec capify .
```

## What's inside?

We made a bunch of additions and customizations. Below we list the most relevant ones.

* **Foreman by default**:
* **Custom foreman upstart template**: we use a custom upstart template, that enables `console log`, allowing `logrotate` to work properly.

## Overriding default templates

We have our opinions, but don't know everything. What works for us, may not fit your needs since each app is a unique snowflake. To take care of that `matross` allows you to define your own templates to use instead of the built in ones. Look at the included ones in `lib/matross/templates` to see how we think things should go.

## Managing application daemons with Foreman

Foreman has freed us of the tedious task of writing `init` and `upstart` scripts. Some of our `matross` recipes automatically add processes - such as the `unicorn` server - to the Procfile.

If you have an application Procfile with custom daemons defined, such as Rake task, they will be concantenated with all the processes defined in `matross`, resulting in one final `Procfile-matross` file that will be used to start your app and export init scrips.

You can specify the number of each instance defined in Procfile-matross using the `foreman_procs` capistrano variable.
Supose you have a process called `dj` and want to export 3 instances of it:

```ruby
set :foreman_procs, {
    dj: 3
}
```

We also modified the default upstart template to log through upstart instead of just piping stdout and stderr into files. Goodbye nocturnal logexplosion. (Like all templates you can override it!)

## Recipes

### Unicorn

Requires that you have [`unicorn`](http://unicorn.bogomips.org/index.html) available in your application. By loading our unicorn recipe, you get [our default configuration](lib/matross/templates/unicorn/unicorn.rb.erb).

Overwritables template: [`unicorn.rb.erb`](lib/matross/templates/unicorn/unicorn.rb.erb)
Procfile task: `web: bundle exec unicorn -c <%= unicorn_config %> -E <%= rails_env %>`

> Variables

| Variable           | Default value                      | Description                        |
| ---                | ---                                | ---                                |
| `:unicorn_config`  | `#{shared_path}/config/unicorn.rb` | Location of the configuration file |
| `:unicorn_log`     | `#{shared_path}/log/unicorn.log`   | Location of unicorn log            |
| `:unicorn_workers` | `1`                                | Number of unicorn workers          |

> Tasks

| Task               | Description                                                      |
| ---                | ---                                                              |
| `unicorn:setup`    | Creates the `unicorn.rb` configuration file in the `shared_path` |
| `unicorn:procfile` | Defines how unicorn should be run in a temporary `Procfile`      |


### Nginx

This recipes creates and configures the virtual_host for the application. [This virtual host] has some sane defaults, suitable for most of our deployments (non-SSL). The file is created at `/etc/nginx/sites-available` and symlinked to `/etc/nginx/sites-enabled`. These are the defaults for the Nginx installation in Ubuntu. You can take a look at [our general `nginx.conf`](https://github.com/innvent/parcelles/blob/puppet/puppet/modules/nginx/files/nginx.conf).

> Variables

| Variable    | Default value | Description                      |
| ---         | ---           | ---                              |
| `:htpasswd` | None          | `htpasswd` user:passwordd format |

> Tasks

| Task           | Description                                       |
| ---            | ---                                               |
| `nginx:setup`  | Creates the virtual host file                     |
| `nginx:reload` | Reloads the Nginx configuration                   |
| `nginx:lock`   | Sets up the a basic http auth on the virtual host |
| `nginx:unlock` | Removes the basic http auth                       |


### MySQL

Requires that you have [`mysql2`](http://rubygems.org/gems/mysql2) available in your application. In our MySQL recipe we dinamically generate a `database.yml` based on the variables that should be set globally or per-stage.

Overwritables template: [`database.yml.erb`](lib/matross/templates/mysql/database.yml.erb)

> Variables

| Variable           | Default value                        | Description                                                                     |
| ---                | ---                                  | ---                                                                             |
| `:database_config` | `#{shared_path}/config/database.yml` | Location of the configuration file                                              |
| `:mysql_host`      | None                                 | MySQL host address                                                              |
| `:mysql_database`  | None                                 | MySQL database name. We automatically substitute dashes `-` for underscores `_` |
| `:mysql_user`      | None                                 | MySQL user                                                                      |
| `:mysql_passwd`    | None                                 | MySQL password                                                                  |

> Tasks

| Task                | Description                                                         |
| ---                 | ---                                                                 |
| `mysql:setup`       | Creates the `database.yml` in the `shared_path`                     |
| `mysql:symlink`     | Creates a symlink for the `database.yml` file in the `current_path` |
| `mysql:create`      | Creates the database if it hasn't been created                      |
| `mysql:schema_load` | Loads the schema if there are no tables in the DB                   |

## Mongoid

Requires that you have [`mongoid`](http://rubygems.org/gems/mongoid) available in your application. In our Mongoid recipe we dinamically generate a `mongoid.yml` based on the variables that should be set globally or per-stage.

Overwritables template: [`mongoid.yml.erb`](lib/matross/templates/mongoid/mongoid.yml.erb)

> Variables

| Variable          | Default value                       | Description                                |
| ---               | ---                                 | ---                                        |
| `:mongoid_config` | `#{shared_path}/config/mongoid.yml` | Location of the mongoid configuration file |
| `:mongo_hosts`    | N/A                                 | **List** of MongoDB hosts                  |
| `:mongo_database` | N/A                                 | MongoDB database name                      |
| `:mongo_user`     | N/A                                 | MongoDB user                               |
| `:mongo_passwd`   | N/A                                 | MongoDB password                           |

> Tasks

| Task                | Description                                                        |
| ---                 | ---                                                                |
| `mongoid:setup`     | Creates the `mongoid.yml` in the `shared_path`                     |
| `mongoid:symlink`   | Creates a symlink for the `mongoid.yml` file in the `current_path` |
