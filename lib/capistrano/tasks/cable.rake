namespace :cable do
  desc 'start action cable daemon'
  task :start do
    on roles(:worker) do
      if test_running(:cable_pid)
        info 'action cable is running...'
      else
        within release_path do
          execute :bundle, "exec puma -C #{fetch(:cable_config)} -e #{fetch(:rails_env)}"
        end
      end
    end
  end

  desc 'restart action cable daemon'
  task :restart do
    on roles(:worker) do
      if test_running(:cable_pid)
        within release_path do
          # puma 也支持发送 USR2 信号, 自动重启.
          # 如果发送 USR1, 等价于: phased-restart
          execute :bundle, "exec pumactl -P #{fetch(:cable_pid)} restart"
        end
      else
        invoke 'cable:start'
      end
    end
  end

  desc 'stop action cable daemon'
  task :stop do
    on roles(:worker) do
      if test_running(:cable_pid)
        within release_path do
          info 'stopping action cable daemon...'
          # 等价于发送 TERM 信号
          execute :bundle, "exec pumactl -P #{fetch(:cable_pid)} stop"
        end
      else
        info 'action cable is not running ...'
      end
    end
  end

  desc 'Add a worker (TTIN)'
  task :add_worker do
    on roles(:app) do
      if test_running(:cable_pid)
        info 'adding worker'
        execute :kill, "-TTIN #{pid(:cable_pid)}"
      else
        info 'action cable is not running...'
      end
    end
  end

  desc 'Remove a worker (TTOU)'
  task :remove_worker do
    on roles(:app) do
      if test_running(:cable_pid)
        info 'removing worker'
        execute :kill, "-TTOU #{pid(:cable_pid)}"
      else
        info 'action cable is not running...'
      end
    end
  end

  desc 'status cable'
  task :status do
    on roles(:app) do
      if test_running(:cable_pid)
        within release_path do
          info 'show cable status'
          execute :bundle, "exec pumactl -P #{fetch(:cable_pid)} status"
          execute "pstree `cat #{fetch(:cable_pid)}` -p"
        end

      else
        info 'cable is not running...'
      end
    end
  end
end

# after 'deploy:published', 'cable:restart'
