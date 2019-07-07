role :web, %w{deployer@152.32.134.198}
role :app, %w{deployer@152.32.134.198}
role :db, %w{deployer@152.32.134.198}
role :worker, %w{deployer@152.32.134.198}

set :branch, 'master'
set :deploy_to, "/home/deployer/apps/#{fetch(:application)}/#{fetch(:application)}_#{fetch(:stage)}"

#  set :ssh_options, {
#    keys: %w(/home/zw963/.ssh/id_rsa),
#    forward_agent: false,
#    auth_methods: %w(password)
#  }
