namespace :fluentd do |_namespace|
  desc "Link project fluentd config into system /etc/td-agent."
  task :config_update, :use_git do |_task_name, args|
    config_update(
      service_name: 'fluentd',
      ubuntu_config_path: '/etc/nginx/td-agent',
      centos_config_path: '/etc/nginx/td-agent',
      restart_service_command: 'systemctl restart td-agent',
      check_running_status_command: 'systemctl status td-agent',
      args: args
    )
  end
end

after 'deploy:finished', 'fluentd:config_update'
