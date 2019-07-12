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

      should_reload_service = false

      project_config_files.each do |config|
        system_config_name = config.relative_path_from(config_root).sub("_#{fetch(:stage)}", '')
        system_config_path = fluentbit_config_dir.join(system_config_name).to_s

        fail "#{config} is not exist." unless test "[ -e #{config} ]"

        next if test "[ -e #{system_config_path} ] && diff #{system_config_path} #{config} -q"

        # if system config exist, and two one exist diff.
        should_reload_service = true

        # if system config exist, and new than project one, i think some one change it.
        if test "[[ -e #{system_config_path} && #{system_config_path} -nt #{config} ]]"
          # should backup it.
          execute :sudo, "mv #{system_config_path} #{system_config_path}-#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')}"
        end

        execute :sudo, "cp -a #{config} #{system_config_path}"
      end

      next info "Skip reboot fluentbit because no config is changed" if should_reload_service == false

      if test 'sudo systemctl restart td-agent-bit'
        info 'fluentbit is reloaded!'
      else
        execute :sudo, "systemctl status td-agent-bit"
      end
    end
  end
end

after 'deploy:finished', 'fluentbit:config_update'
