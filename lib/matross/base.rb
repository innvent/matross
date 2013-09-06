def template(from, to)
  override_template = File.join(Dir.pwd, 'config/matross', from)
  if File.exist?(override_template)
    erb = File.read(override_template)
  else
    erb = File.read(File.expand_path("../templates/#{from}", __FILE__))
  end
  put ERB.new(erb).result(binding), to
end
