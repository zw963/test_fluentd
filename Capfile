# Load DSL and set up stages
require 'capistrano/setup'

# Include default deployment tasks
require 'capistrano/deploy'

require 'capistrano/scm/git'
install_plugin Capistrano::SCM::Git
require 'capistrano/rvm'

# capistrano/rails 包含以下三部分.
require 'capistrano/bundler'
require 'capistrano/rails/assets'
require 'capistrano/rails/migrations'

# Load custom tasks from `lib/capistrano/tasks` if you have any defined
Dir.glob('lib/capistrano/tasks/*.rake').each {|r| import r }

def test_running(cap_pid_file_sym)
  pid_file = fetch(cap_pid_file_sym)
  test("[ -f #{pid_file} ] && kill -0 `cat #{pid_file}`")
end

def pid(cap_pid_file_sym)
  pid_file = fetch(cap_pid_file_sym)
  "`cat #{pid_file}`"
end

def config_update(ubuntu_config_path:, centos_config_path:, service_name:, restart_service_command:, check_config_command: nil, check_running_status_command: nil, args:)
  on roles(:worker) do
    if test '[[ $(cat /etc/*-release) =~ Ubuntu|Mint ]]'
      system_config_dir = Pathname(ubuntu_config_path)
    elsif test '[[ $(cat /etc/*-release) =~ CentOS ]]'
      system_config_dir = Pathname(centos_config_path)
    else
      info "Current linux distribution not supported, skip `#{service_name}`!"
      exit
    end

    if not args[:use_git].nil?
      invoke 'git:clone'
      invoke 'git:update'
      invoke 'git:create_release'
      invoke 'deploy:set_current_revision'
      invoke 'deploy:symlink:linked_dirs'
    end

    project_config_dir = Pathname("#{deploy_to}/current/config/containers/#{service_name}/config")
    project_config_suffix = "_#{fetch(:stage)}"
    project_config_files = capture("find #{project_config_dir} -name *#{project_config_suffix}*").split("\n").map {|e| Pathname(e) }

    should_reload_service = false

    project_config_files.each do |project_config_file|
      system_config_name = project_config_file.relative_path_from(project_config_dir).sub(project_config_suffix, '')
      system_config_file = system_config_dir.join(system_config_name)
      system_sub_conf_dir = system_config_file.dirname

      execute "test -d #{system_sub_conf_dir} || sudo mkdir -pv #{system_sub_conf_dir}"

      # if system config exist, and two one no diff.
      next if test "[ -e #{system_config_file} ] && diff #{system_config_file} #{project_config_file} -q"

      should_reload_service = true

      # if system config exist, and new than project one, i think some one change it.
      if test "[[ -e #{system_config_file} && #{system_config_file} -nt #{project_config_file} ]]"
        # should backup it.
        execute :sudo, "mv #{system_config_file} #{system_config_file}-#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')}"
      end

      execute :sudo, "cp -a #{project_config_file} #{system_config_file}"
    end

    next info "Skip reboot #{service_name} because no config is changed." if should_reload_service == false

    unless check_config_command.nil?
      info 'Checking config'
      execute :sudo, check_config_command
    end

    info 'Restart service'
    execute :sudo, restart_service_command

    unless check_running_status_command.nil?
      info 'Checking running status'
      execute :sudo, check_running_status_command
    end

    info "#{service_name} is reloaded!"
  end
end
