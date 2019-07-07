set :application, 'test_fluentd'
# 本地 git 示例: ssh://git@example.com:3000/~/me/my_repo.git
# svn 示例: svn://myhost/myrepo/#{fetch(:branch)}
set :repo_url, 'git@github.com:zw963/test_fluentd'
set :rails_env, -> { fetch(:stage) }
set :rvm_ruby_version, "ruby-2.6.1@#{fetch(:application)}"
set :keep_releases, 5
set :local_user, -> { Etc.getlogin }
set :conditionally_migrate, true

set :pid_dir, -> { "#{fetch(:deploy_to)}/shared/tmp/pids" }
set :config_dir, -> { "#{fetch(:deploy_to)}/current/config" }
set :containers_dir, -> { "#{fetch(:config_dir)}/containers" }
set :puma_pid, -> { "#{fetch(:pid_dir)}/puma.pid" }
set :puma_config, -> { "#{fetch(:containers_dir)}/app/config/puma_production.rb" }
set :cable_pid, -> { "#{fetch(:pid_dir)}/cable.pid" }
set :cable_config, -> { "#{fetch(:config_dir)}/cable.rb" }
set :sidekiq_pid, -> { "#{fetch(:pid_dir)}/sidekiq.pid" }

set :linked_files, %w{
}
set :linked_dirs, %w{
  log
  tmp
  public/assets
  public/packs
  public/uploads
  node_modules
}
