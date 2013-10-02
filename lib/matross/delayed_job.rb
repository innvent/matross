dep_included? 'delayed_job'

namespace :delayed_job do

  desc "Writes the delayed job part of the Procfile"
  task :procfile, :roles => :dj do
    procfile_template = <<-EOF.gsub(/^\s+/, '')
      dj: RAILS_ENV=<%= rails_env %> bundle exec rake jobs:work
    EOF
    procfile = ERB.new(procfile_template, nil, '-')
    put procfile.result(binding), "#{shared_path}/Procfile.dj"
  end
  after "foreman:pre_setup", "delayed_job:procfile"

end
