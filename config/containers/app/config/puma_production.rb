# -*- coding: utf-8; mode:ruby; -*-

fail 'Need specify APP_FULL_PATH' if ENV['APP_FULL_PATH'].nil?

app_path = ENV['APP_FULL_PATH']

# Following instruction is need for phased restart.
directory app_path

pid_dir = "#{app_path}/tmp/pids"
FileUtils.mkdir_p pid_dir
pidfile "#{pid_dir}/puma.pid"
state_path "#{pid_dir}/puma.state"

environment ENV.fetch('RAILS_ENV', 'production')
threads 0, ENV.fetch('RAILS_MAX_THREADS', 16).to_i
require 'etc'; workers ENV.fetch('WEB_CONCURRENCY', Etc.nprocessors).to_i
# socket 文件放到 tmp 目录下, 避免 socket 在系统 /tmp 某些 linux 发布版拒绝访问.
bind "unix://#{app_path}/tmp/puma.sock"
# port = ENV.fetch('DEFAULT_PORT', 3000)

if ENV['RAILS_LOG_TO_STDOUT'] == 'true'
  stdout_redirect "log/puma.access.log", "log/puma.err.log"
  daemonize
end

# bind "tcp://0.0.0.0:#{port}" unless port.nil?

plugin :tmp_restart

# Following is need for phased restart.
# prune_bundler
