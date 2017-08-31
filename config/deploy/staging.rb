# Capistrona 3.x Koha Vagrant/Lab stage
# config/deploy/staging.rb

server 'koha-staging.ub.gu.se',
  roles: %w{web app db},
  primary: false,
  user: 'koha',
  port: 22,
  koha_instance_name: 'koha',
  koha_plack_enabled: false

set :deploy_to, '/home/koha/koha-staging'
set :branch, 'release-20170824'
set :keep_releases, 5 # Save space on virtual machines
