namespace :sidekiq do
  desc 'start sidekiq daemon'
  task :start do
    on roles(:worker) do
      if test_running(:sidekiq_pid)
        info 'sidekiq is running...'
      else
        within release_path do
          execute :bundle, "exec sidekiq -e #{fetch(:rails_env)} -d"
        end
      end
    end
  end

  desc 'restart sidekiq daemon'
  task :restart do
    on roles(:worker) do
      invoke 'sidekiq:stop' if test_running(:sidekiq_pid)
      invoke 'sidekiq:start'
    end
  end

  desc 'stop sidekiq daemon'
  task :stop do
    on roles(:worker) do
      if test_running(:sidekiq_pid)
        within release_path do
          # 这里等价于发送 TERM 信号
          execute :bundle, "exec sidekiqctl stop #{fetch(:sidekiq_pid)}"
          # execute :bundle, "exec kill -TERM #{pid(:sidekiq_pid)}"
        end
      else
        info 'sidekiq is not running...'
      end
    end
  end

  desc 'quiet sidekiq daemon'
  task :quiet do
    on roles(:worker) do
      if test_running(:sidekiq_pid)
        within release_path do
          info 'quieting sidekiq...'
          # execute :kill, "-USR1 #{pid(:sidekiq_pid)}"
          # Sidekiq 5.0 版本开始, -USR1 deprecated, 转而采用 TSTP.
          # TSTP 表示 Threads SToP, 同时可以在 JRuby 下工作.
          execute :bundle, "exec sidekiqctl quiet #{fetch(:sidekiq_pid)}"
        end
      else
        info 'sidekiq is not running...'
      end
    end
  end

  desc 'status sidekiq'
  task :status do
    on roles(:app) do
      if test_running(:sidekiq_pid)
        info 'show sidekiq status'
        execute "pstree `cat #{fetch(:sidekiq_pid)}` -p"
      else
        info 'sidekiq is not running...'
      end
    end
  end
end

# 模式取消重启 siekiq, 如需添加, 手动移除注释.
# before 'deploy:started', 'sidekiq:quiet'
# after 'deploy:published', 'sidekiq:restart'
