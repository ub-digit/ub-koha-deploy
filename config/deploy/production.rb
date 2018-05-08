# Capistrano 3.x Koha Vagrant/Production stage
# config/deployproduction.rb

server 'koha.ub.gu.se',
  roles: %w{web app db},
  primary: false,
  user: 'koha',
  port: 22,
  koha_instance_name: 'koha',
  koha_plack_enabled: true

set :deploy_to, '/home/koha/koha-production'
set :keep_releases, 10 # Save space on virtual machines

release_prefix = 'release-2018.04-'
set :koha_deploy_branches_prefix, release_prefix
set :koha_deploy_release_branch_prefix, release_prefix
set :koha_deploy_release_branch_start_point, release_prefix + 'master'
