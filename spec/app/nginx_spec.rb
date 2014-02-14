require "spec_helper"
require "support/test_app"

describe "using Matross' nginx recipe" do
  before(:all) do
    TestApp.install
  end

  describe "when run task nginx:setup" do
    before(:all) do 
      File.open(TestApp.capfile, "a") {|f| f.write "require 'matross/nginx'" }
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
end
