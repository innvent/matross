load "deploy/assets"

namespace :deploy do
  namespace :assets do
    desc "Run Rails asset pipeline locally"
    task :precompile, :roles => :web do
      run_locally "#{rake} assets:clean && #{rake} assets:precompile"
      run_locally "cd public && tar -jcf assets.tar.bz2 assets"
      top.upload "public/assets.tar.bz2", "#{shared_path}", :via => :scp
      run "cd #{shared_path} && tar -jxf assets.tar.bz2 && rm assets.tar.bz2"
      run_locally "rm public/assets.tar.bz2"
      run_locally "#{rake} assets:clean"
    end
  end
end
