require 'bundler'
require 'matross/errors'

def template(from, to)
  override_template = File.join(Dir.pwd, 'config/matross', from)
  if File.exist?(override_template)
    erb = File.read(override_template)
  else
    erb = File.read(File.expand_path("../templates/#{from}", __FILE__))
  end
  put ERB.new(erb).result(binding), to
end

def dep_included?(dependency)
  lockfile = Bundler::LockfileParser.new(Bundler.read_file(Bundler.default_lockfile)) 
  if not lockfile.specs.any? { |gem| gem.name == dependency} then
    raise Matross::MissingDepError, "recipe requires the #{dependency} gem"
  end
end
