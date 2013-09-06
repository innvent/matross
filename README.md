# matross

## Usage

Put matross in the `:development` group of your `Gemfile`:

```ruby
group :development do
    gem 'matross', :git => 'git://github.com/innvent/matross.git'
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
* **User template overwrite**:

