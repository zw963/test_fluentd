namespace :fluentbit do |_namespace|
  desc "Link project fluentbit config into system /etc/td-agent-bit."
  task :config_update, :use_git do |_task_name, args|
    config_update(
      service_name: 'fluentbit',
      ubuntu_config_path: '/etc/nginx/td-agent-bit',
      centos_config_path: '/etc/nginx/td-agent-bit',
      restart_service_command: 'systemctl restart td-agent-bit',
      check_running_status_command: 'systemctl status td-agent-bit',
      args: args
    )
  end
end

after 'deploy:finished', 'fluentbit:config_update'
