role :web, %w{deployer@114.112.255.34}
role :app, %w{deployer@114.112.255.34}
role :db, %w{deployer@114.112.255.34}
role :worker, %w{deployer@114.112.255.34}

set :branch, 'master'
set :deploy_to, "/home/deployer/apps/#{fetch(:application)}/#{fetch(:application)}_#{fetch(:stage)}"

#  set :ssh_options, {
#    keys: %w(/home/zw963/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
