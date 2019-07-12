# namespace :nginx do
#   ns_name = namespace.scope.path

#   desc "Link project #{ns_name} config into system #{ns_name} config."
#   task :config_update do
#     on roles(:worker) do
#       if test '[[ $(cat /etc/*-release) =~ Ubuntu|Mint ]]'
#         nginx_config_dir = '/etc/nginx/sites-enabled'
#       elsif test '[[ $(cat /etc/*-release) =~ CentOS ]]'
#         nginx_config_dir = '/etc/nginx/conf.d'
#       else
#         info "Skip `#{ns_name}:update`"
#         exit
#       end

#       # if test('sudo nginx -t')
#       project_config_dir = Pathname("#{deploy_to}/current/config/containers/#{ns_name}/config")

#       # project_nginx_config = "#{deploy_to}/current/config/containers/nginx/config/nginx_#{fetch(:stage)}.conf"

#       config = "#{nginx_config_dir}/#{fetch(:application)}_#{fetch(:stage)}.conf"
#       config_file_pattern = "*_#{fetch(:stage)}.conf"

#       project_config_files = capture("find #{project_config_dir} -name #{config_file_pattern}").split("\n").map {|e| Pathname(e) }

#       if test "[ -f #{config} -a ! -L #{config} ]"
#         # Backup not a symlink config
#         execute :sudo, "mv #{config} /#{config}-#{Time.now.strftime('%Y-%m-%d_%H:%M:%S')}"
#       end

#       if test "[ -e #{project_nginx_config} ]"
#         execute :sudo, "ln -sf #{project_nginx_config} #{config}"
#         execute :sudo, 'nginx -t'
#         execute :sudo, 'nginx -s reload'
#         info 'nginx is reloaded!'
#       else
#         fail "#{project_nginx_config} is not exist."
#       end
#       # else
#       #   fail 'nginx start not correct.'
#       # end
#     end
#   end
# end

# after 'deploy:finished', 'nginx:config_update'
