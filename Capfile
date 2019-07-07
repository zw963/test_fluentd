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
