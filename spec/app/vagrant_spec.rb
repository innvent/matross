require "spec_helper"

describe "Vagrant provisioning" do

  context package("git-core") do
    it { should be_installed }
  end
  
  context package("nginx") do
    it { should be_installed }
  end
  
  context command("rbenv versions") do
    let(:pre_command) { "source ~/.bash_profile" }
    let(:ruby_version) { File.read("../../.ruby-version").chomp  }
    its(:stdout) { should match /#{@ruby_version}/ }
  end
end
