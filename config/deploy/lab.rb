# Capistrona 3.x Koha Vagrant/Lab stage
# config/deploy/lab.rb

server 'koha-lab.ub.gu.se',
  roles: %w{web app db},
  primary: false,
  user: 'apps',
  port: 22,
  koha_instance_name: 'koha',
  koha_plack_enabled: true

set :deploy_to, '/home/apps/koha-lab'
set :keep_releases, 5 # Save space on virtual machines
