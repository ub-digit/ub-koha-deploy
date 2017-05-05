# Load default values the capistrano 3.x way.
# See https://github.com/capistrano/capistrano/pull/605
# TODO: Require template plugin, how?
namespace :load do
  task :defaults do
    set :templating_paths, fetch(:templating_paths) << "lib/capistrano/templates"
  end
end

# Settable?
# :locale_data_path ?
# Data directory for locally stored data
file 'data' do
  mkdir('data')
end

namespace :'koha' do
  #Is this kosher?
  def data_permit_write
    puts "Writing data not permitted for stage '#{fetch(:stage)}'." unless fetch(:koha_data_permit_write)
    fetch(:koha_data_permit_write)
  end

  namespace :'export' do
    desc "Export database"
    task :'database' do
      invoke 'koha:stash-database'
      invoke 'koha:stash-database:download'
    end
  end

  desc "Export data"
  task :'export' do
    invoke 'koha:export:database'
  end

  namespace :'import' do
    desc "Import database"
    task :'database' do
      next unless data_permit_write
      invoke 'koha:stash-database:upload'
      invoke 'koha:stash-database:apply'
    end
  end

  desc "Import data"
  task :'import' do
    next unless data_permit_write
    invoke 'koha:import:database'
  end

  #TODO: namespace stash
  namespace :'stash-database' do
    desc "Remove stashed database"
    task :remove do
      on release_roles :app do
        within current_path do
          execute :rm, current_path.join('database.sql')
        end
      end
    end

    desc "Download stashed database"
    task :download => 'data' do
      # Check if extist and possible run stash-database if not?
      on release_roles :app do
        download! current_path.join('database.sql'), 'data'
      end
    end

    desc "Upload stashed database"
    # TODO: 'data/database.sql'? Nah, makes no sense to download -> upload
    task :upload => 'data' do
      on release_roles :app do
        upload! File.join('data', 'database.sql'), current_path.join('database.sql')
      end
    end

    task :'apply' do
      next unless data_permit_write
      on release_roles :app do
        within current_path do
          puts "TODO: Restore stashed db\n\n\n"
          invoke 'koha:clear-cache'
        end
      end
    end
  end

  desc "Stash database"
  task :'stash-database' do
    on release_roles(:app) do |server|
      within current_path do
        output = capture :sudo, 'koha-dump', server.fetch(:koha_instance_name)
        database_dump_path, config_dump_path = output.lines[1..2].map { |line| line.split(' ').last }
        execute :sudo, :mkdir, '-p', 'data'
        execute :sudo, :mv, database_dump_path, File.join('data', 'database.sql.gz')
        execute :sudo, :mv, config_dump_path, File.join('data', 'config.tar.gz')
        # server.group??
        execute :sudo, :chown, "#{server.user}:#{server.user}", '-R', 'data'
      end
    end
  end

  #TODO: Task for enabling/disabling plack,
  # should be simple enough

  desc "Clear all caches"
    task :'clear-cache' do
    on release_roles :app do |server|
      execute :sudo, '/etc/init.d/memcached', 'restart'
      if server.fetch(:koha_plack_enabled)
        execute :sudo, 'koha-plack', '--restart', server.fetch(:koha_instance_name)
      end
    end
  end

  desc "Put Koha in maintenance mode"
  task :'maintenance-mode-enable' do
    on release_roles :app do |server|
      execute :sudo, 'koha-disable', server.fetch(:koha_instance_name)

    end
  end

  desc "Take Koha off maintenance mode"
  task :'maintenance-mode-disable' do
    on release_roles :app do |server|
      execute :sudo, 'koha-enable', server.fetch(:koha_instance_name)

    end
  end

  desc 'Apply any database updates required.'
  task :updatedb do
    on release_roles :app do |server|
      execute :sudo, 'koha-shell', '-c', release_path.join('installer/data/mysql/updatedatabase.pl'), server.fetch(:koha_instance_name)
    end
  end

  #TODO: perhaps don't run this by default
  desc 'Rebuild Elasticsearch index.'
  task :'rebuild-elasticsearch' do
    on release_roles :app do |server|
      execute :sudo, 'koha-shell', '-c', release_path.join('misc/search_tools/rebuild_elastic_search.pl'), '-d', server.fetch(:koha_instance_name)
    end
  end
  #TODO restore/revert/import?
  #task :restore_database
end

namespace :deploy do
  before :starting, :set_command_map_paths do
    #SSHKit.config.command_map[:koha_stash_files_apply_merge] = shared_path.join('koha-stash-files-apply-merge.sh');
    # Temporary hack, just hard coded paths, proper way of doing this?
    SSHKit.config.command_map[:koha_enable] = '/usr/sbin/koha-disable'
    #SSHKit.config.command_map[:koha_disable] = '/usr/sbin/koha-disable'
    #SSHKit.config.command_map[:koha_dump] = '/usr/sbin/koha-dump'
    #SSHKit.config.command_map[:koha_plack] = '/usr/sbin/koha-plack'
    #SSHKit.config.command_map[:memcached] = '/etc/init.d/memcached'
    #SSHKit.config.command_map[:memcached] = '/etc/init.d/memcached'
    #koha_shell_path = '/usr/sbin/koha-shell'
    #SSHKit.config.command_map[:rebuild_elasticsearch] = [koha_shell_path, '-c', release_path.join('misc/search_tools/rebuild_elastic_search.pl')].join(' ')
    #SSHKit.config.command_map[:update_database] = [koha_shell_path, '-c', release_path.join('installer/data/mysql/updatedatabase.pl')].join(' ')
  end
  after :starting, :backup_previous_revision_database do
    if fetch(:previous_revision)
      invoke 'koha:stash-database'
    end
  end
  after :publishing, 'koha:maintenance-mode-enable'
  after :publishing, 'koha:clear-cache'
  after :publishing, 'koha:updatedb'
  after :publishing, 'koha:maintenance-mode-disable'
end
