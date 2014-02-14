require "spec_helper"
require "support/test_app"

describe "using Matross' nginx recipe" do
  before(:all) do
    TestApp.install
    File.open(TestApp.capfile, "a") {|f| f.write "require 'matross/nginx'" }
    File.open(TestApp.test_stage_path, "a") {|f| f.write "\nset :htpasswd, 'test:test'" }
  end

  describe "when run task nginx:setup" do
    before(:all) do 
      TestApp.run "bundle exec cap test nginx:setup"
    end

    context file("/etc/nginx/sites-available/test_app") do
      it { should be_file }
    end

    context file("/etc/nginx/sites-enabled/test_app") do
      it { should be_linked_to "/etc/nginx/sites-available/test_app" }
    end

    context command("sudo nginx -t") do
        it { should return_exit_status 0 }
    end
  end

  describe "when run task nginx:lock" do
    before(:all) do 
      TestApp.run "bundle exec cap test nginx:setup"
      TestApp.run "bundle exec cap test nginx:lock"
    end

    context file("/home/vagrant/test_app/shared/.htpasswd") do
      it { should be_file }
      it { should contain "test:test" }
    end

    context file("/etc/nginx/sites-enabled/test_app") do
      it { should contain "auth_basic" }
    end

    context command("curl $(hostname -f) -I") do
      it { should return_stdout /401 Unauthorized/}
    end
  end

  describe "when run task nginx:unlock" do
    before(:all) do 
      TestApp.run "bundle exec cap test nginx:setup"
      TestApp.run "bundle exec cap test nginx:lock"
      TestApp.run "bundle exec cap test nginx:unlock"
      sleep 1 # Give time for nginx reload to take effect
    end

    context file("/etc/nginx/sites-enabled/test_app") do
      it { should_not contain "auth_basic" }
    end

    context command("curl $(hostname -f) -I") do
      it { should_not return_stdout /401 Unauthorized/}
    end
  end

end
