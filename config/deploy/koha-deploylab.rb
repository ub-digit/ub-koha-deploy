# Capistrona 3.x Koha Vagrant/Testing stage
# config/depeploy/testing.rb

if not ENV.has_key?('KOHA_DEPLOY_TESTING_DEVBOX_ID')
  raise "Environmental variable $KOHA_DEPLOY_TESTING_DEVBOX_ID must be set before deploying testing. Run `vagrant global-status` to list all boxes with ids"
end

vagrant_box_id = ENV['KOHA_DEPLOY_TESTING_DEVBOX_ID']

vagrant_ssh_config = `vagrant ssh-config #{vagrant_box_id}`.lines[1..-1].map(&:strip).inject({}) do |config, line|
  k, v = line.split(/\s/, 2).map(&:strip)
  config[k] = v
  config
end

server vagrant_ssh_config['HostName'],
  roles: %w{web app db},
  primary: true, # TODO: Can't remember the significance of this, find out
  user: vagrant_ssh_config['User'],
  port: vagrant_ssh_config['Port'],
  ssh_options: {
    keys: [vagrant_ssh_config['IdentityFile']],
    forward_agent: vagrant_ssh_config['ForwardAgent'] == 'yes'
  },
  koha_instance_name: 'kohadev',
  koha_plack_enabled: false

set :deploy_to, '/home/vagrant/koha'
set :keep_releases, 2 # Save space on virtual machines
