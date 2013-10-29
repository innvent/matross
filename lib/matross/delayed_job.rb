dep_included? 'delayed_job'

_cset :dj_queues, nil

namespace :delayed_job do

  desc "Writes the delayed job part of the Procfile"
  task :procfile, :roles => :dj do
    procfile_template = <<-EOF.gsub(/^\s+/, '')
      <% if dj_queues -%>
        <% dj_queues.each do |queue_name| -%>
          dj_<%= queue_name %>: bundle exec rake jobs:work QUEUE=<%= queue_name %>
        <% end -%>
      <% else -%>
        dj: bundle exec rake jobs:work
      <% end -%>
    EOF
    procfile = ERB.new(procfile_template, nil, '-')
    put procfile.result(binding), "#{shared_path}/Procfile.dj"
  end
  after "foreman:pre_setup", "delayed_job:procfile"

end
