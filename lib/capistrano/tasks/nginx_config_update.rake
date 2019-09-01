namespace :nginx do |_namespace|
  desc "Link project nginx config into system /etc/nginx."
  task :config_update, :use_git do |_task_name, args|
    config_update(
      service_name: 'nginx',
      ubuntu_config_path: '/etc/nginx/sites-enabled',
      centos_config_path: '/etc/nginx/conf.d',
      check_config_command: 'nginx -t',
      restart_service_command: 'nginx -s reload',
      args: args
    )
  end
end

after 'deploy:finished', 'nginx:config_update'
