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

set :koha_deploy_branches_prefix, 'release-18.04-'
set :koha_deploy_release_branch_prefix, 'release-18.04-'
