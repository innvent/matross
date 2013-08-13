# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "matross"
  gem.homepage = "http://github.com/innvent/matross"
  gem.license = "MIT"
  gem.summary = %Q{Our collection of opnionated Capistrano recipes}
  gem.description = %Q{Our collection of opnionated Capistrano recipes}
  gem.email = ["artur.rodrigues@innvent.com.br", "joao.sa@innvent.com.br"]
  gem.authors = ["Artur Rodrigues" , "Joao Sa"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new
