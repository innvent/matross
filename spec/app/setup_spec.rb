require "spec_helper"
require_relative "../support/test_app"

describe "Test App" do
  before(:all) {
    @test_app_path = "/tmp/test_app"

    TestApp.install
  }

  it "should install to #{@test_app_path}" do
    File.directory?(@test_app_path).should be_true
  end

  it "should create Capfile" do
    File.exists?(File.join(@test_app_path, "Capfile"))
  end

  context file("/home/vagrant/test_app") do
    before { TestApp.deploy }
    it { should be_directory }
  end
end
