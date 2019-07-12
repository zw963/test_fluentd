namespace :fluentbit do |namespace|
  ns_name = namespace.scope.path
  service_name = 'td-agent-bit'

  desc "Link project #{ns_name} config into system #{ns_name} config."
  task :config_update do
    on roles(:worker) do
      if test '[[ $(cat /etc/*-release) =~ Ubuntu|Mint ]]'
        system_config_dir = Pathname("/etc/#{service_name}")
      elsif test '[[ $(cat /etc/*-release) =~ CentOS ]]'
        system_config_dir = Pathname("/etc/#{service_name}")
      else
        info "Skip `#{ns_name}:update`"
        exit
      end

      project_config_dir = Pathname("#{deploy_to}/current/config/containers/#{ns_name}/config")
      project_config_suffix = "_#{fetch(:stage)}"
      project_config_files = capture("find #{project_config_dir} -name *#{project_config_suffix}.conf").split("\n").map {|e| Pathname(e) }

      should_reload_service = false

      project_config_files.each do |project_config_file|
        system_config_name = project_config_file.relative_path_from(project_config_dir).sub(project_config_suffix, '')
        system_config_file = system_config_dir.join(system_config_name).to_s

        fail "#{project_config_file} is not exist." unless test "[ -e #{project_config_file} ]"

        next if test "[ -e #{system_config_file} ] && diff #{system_config_file} #{project_config_file} -q"

        # if system config exist, and two one exist diff.
        should_reload_service = true

        # if system config exist, and new than project one, i think some one change it.
        if test "[[ -e #{system_config_file} && #{system_config_file} -nt #{project_config_file} ]]"
          # should backup it.
          execute :sudo, "mv #{system_config_file} #{system_config_file}-#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')}"
        end

        execute :sudo, "cp -a #{project_config_file} #{system_config_file}"
      end

      next info "Skip reboot #{ns_name} because no config is changed" if should_reload_service == false

      if test "sudo systemctl restart #{service_name}"
        info "#{ns_name} is reloaded!"
      else
        execute :sudo, "systemctl status #{service_name}"
      end
    end
  end
end

after 'deploy:finished', 'fluentbit:config_update'
