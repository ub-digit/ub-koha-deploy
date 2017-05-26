# Capistrona 3.x koha-lab
# config/depeploy/lab.rb

server "koha-lab.ub.gu.se",
  roles: %w{web app db},
  primary: true, # TODO: Can't remember the significance of this, find out
  user: 'koha',
  port: 22,
  koha_instance_name: 'koha',
  koha_plack_enabled: false

set :deploy_to, '/home/koha/koha-lab'
set :keep_releases, 5
