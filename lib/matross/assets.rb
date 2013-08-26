load "deploy/assets"

namespace :deploy do
  namespace :assets do
    desc "Run Rails asset pipeline locally"
    task :precompile, :roles => :web do
      run_locally <<-CMD.gsub(/^\s+/, '')
        RAILS_ENV=#{rails_env.to_s.shellescape} #{rake} assets:clean &&
        RAILS_ENV=#{rails_env.to_s.shellescape} #{rake} assets:precompile &&
        cd public && tar -jcf assets.tar.bz2 assets
      CMD
      top.upload "public/assets.tar.bz2", "#{shared_path}", :via => :scp
      run "cd #{shared_path} && tar -jxf assets.tar.bz2 && rm assets.tar.bz2"

      # Clean up temporary local assets
      run_locally <<-CMD.gsub(/^\s+/, '')
        rm public/assets.tar.bz2 &&
        RAILS_ENV=#{rails_env.to_s.shellescape} #{rake} assets:clean
      CMD
    end

  end
end
