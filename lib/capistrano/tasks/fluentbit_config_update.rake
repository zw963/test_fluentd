namespace :fluentbit do
  desc 'Link fluentbit config into system fluentbit config.'

  task :config_update do
    on roles(:worker) do
      if test '[[ $(cat /etc/*-release) =~ Ubuntu|Mint ]]'
        fluentbit_config_dir = Pathname('/etc/td-agent-bit')
      elsif test '[[ $(cat /etc/*-release) =~ CentOS ]]'
        fluentbit_config_dir = Pathname('/etc/td-agent-bit')
      else
        info 'Skip `fluentbit:update`'
        exit
      end

      config_root = Pathname("#{deploy_to}/current/config/containers/fluentbit/config")
      config_file_pattern = "*_#{fetch(:stage)}.conf"

      project_config_files = capture("find #{config_root} -name #{config_file_pattern}").split("\n").map {|e| Pathname(e) }

      project_config_files.each do |config|
        system_config_name = config.relative_path_from(config_root).sub("_#{fetch(:stage)}", '')
        system_config_path = fluentbit_config_dir.join(system_config_name).to_s

        # 如果系统的 config 文件存在, 而且不是一个符号链接, 这通常是原有的配置文件,
        # 此时, 应该首先备份它.
        if test "[ -f #{system_config_path} -a ! -L #{system_config_path} ]"
          # Backup not a symlink config
          execute :sudo, "mv #{system_config_path} #{system_config_path}-#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')}"
        end

        if test "[ -e #{config} ]"
          execute :sudo, "ln -sf #{config} #{system_config_path}"
        else
          fail "#{config} is not exist."
        end
      end

      if test 'sudo systemctl restart td-agent-bit'
        info 'fluentbit is reloaded!'
      else
        execute :sudo, "systemctl status td-agent-bit"
      end
    end
  end
end

after 'deploy:finished', 'fluentbit:config_update'
