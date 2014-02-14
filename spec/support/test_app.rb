require "fileutils"
module TestApp
  extend self

  def install
    install_test_app_with(default_config)
  end

  def stage
    "test"
  end

  def test_app_path
    Pathname.new("/tmp/test_app")
  end

  def test_stage_path
    test_app_path.join("config/deploy/#{stage}.rb")
  end

  def gemfile
    test_app_path.join("Gemfile")
  end

  def ruby_version
    test_app_path.join(".ruby-version")
  end

  def path_to_matross
    File.expand_path(".")
  end

  def run(command)
    Dir.chdir(test_app_path) do
      %x{#{command}}
    end
  end

  def default_config
    <<-'EOF'.gsub(/^\s+/, '')
      set :application, "test_app"
      set :user,        "vagrant"
      set :repo_url,    "https://github.com/innvent/matross"
      set :branch,      "master"
      set :deploy_to,   "/home/#{fetch :user}/#{fetch :application}"

      server '127.0.0.1:2222', user: fetch(:user), roles: %w{web app}
      set :ssh_options, { keys: "#{ENV['HOME']}/.vagrant.d/insecure_private_key" }
    EOF
  end

  def install_test_app_with(config)
    create_test_app
    run "bundle exec cap install STAGES=#{stage} -s"
    write_local_deploy_file(config)
  end

  def create_test_app
    FileUtils.rm_rf(test_app_path)
    FileUtils.mkdir(test_app_path)

    File.open(gemfile, "w+") do |file|
      file.write "gem 'matross', path: '#{path_to_matross}'"
    end

    File.open(ruby_version, "w+") do |file|
      file.write "#{File.read(".ruby-version") }"
    end

    run "bundle"
  end

  def write_local_deploy_file(config)
    File.open(test_stage_path, "w") do |file|
      file.write(config)
    end
  end

  def deploy
    run "bundle exec cap test deploy"
  end
end
