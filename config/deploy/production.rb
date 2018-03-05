# Capistrano 3.x Koha Vagrant/Production stage
# config/deployproduction.rb

server 'koha.ub.gu.se',
  roles: %w{web app db},
  primary: false,
  user: 'koha',
  port: 22,
  koha_instance_name: 'koha',
  koha_plack_enabled: true

set :deploy_to, '/home/koha/koha'
set :keep_releases, 10 # Save space on virtual machines
