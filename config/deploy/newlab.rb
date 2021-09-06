# Capistrona 3.x Koha Vagrant/Lab stage
# config/deploy/staging.rb

server '89.45.233.21',
  roles: %w{web app db},
  primary: false,
  user: 'apps',
  port: 22,
  koha_instance_name: 'koha',
  koha_plack_enabled: true

set :deploy_to, '/home/apps/koha-lab'
set :keep_releases, 5
