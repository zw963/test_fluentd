namespace :puma do
  desc 'start puma daemon'
  task :start do
    on roles(:worker) do
      if test_running(:puma_pid)
        info 'puma is running...'
      else
        within release_path do
          execute :bundle, "exec puma -C #{fetch(:puma_config)} -e #{fetch(:rails_env)}"
        end
      end
    end
  end

  desc 'restart puma daemon'
  task :restart do
    on roles(:worker) do
      if test_running(:puma_pid)
        # within release_path do
        # 是否 db 有修改
        condition1 = "! diff -q #{release_path}/db #{current_path}/db"
        # 是否 gem 有修改
        condition2 = "! diff -q #{release_path}/Gemfile.lock #{current_path}/Gemfile.lock"

        info '[puma:restart] Checking changes in db'
        if test(condition1) or test(condition2)
          execute :kill, "-USR2 #{pid(:puma_pid)}"
        else
          info '[puma:restart] Nothing changed in db, use zero downtime restart'
          execute :kill, "-USR1 #{pid(:puma_pid)}"
        end
        # end
      else
        invoke 'puma:start'
      end
    end
  end

  desc 'stop puma daemon'
  task :stop do
    on roles(:worker) do
      if test_running(:puma_pid)
        within release_path do
          info 'stopping puma daemon...'
          execute :kill, "-TERM #{pid(:puma_pid)}"
        end
      else
        info 'puma is not running ...'
      end
    end
  end

  desc 'Add a worker (TTIN)'
  task :add_worker do
    on roles(:app) do
      if test_running(:puma_pid)
        info 'adding worker'
        execute :kill, "-TTIN #{pid(:puma_pid)}"
      else
        info 'puma is not running...'
      end
    end
  end

  desc 'Remove a worker (TTOU)'
  task :remove_worker do
    on roles(:app) do
      if test_running(:puma_pid)
        info 'removing worker'
        execute :kill, "-TTOU #{pid(:puma_pid)}"
      else
        info 'puma is not running...'
      end
    end
  end

  desc 'status puma'
  task :status do
    on roles(:app) do
      if test_running(:puma_pid)
        within release_path do
          info 'show puma status'
          execute "pstree #{pid(:puma_pid)} -p"
        end

      else
        info 'puma is not running...'
      end
    end
  end
end

after 'deploy:published', 'puma:restart'
