require 'shellwords'
require 'yaml'
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
#file 'data' do
#  mkdir('data')
#end
#
# Provide name spaced data directory for value sources
file 'data/value_sources' do
  mkdir('data/value_sources')
end

namespace :'apache' do

  desc 'Restart apache'
  task :'restart' do
    on release_roles :app do
        execute :sudo, '/etc/init.d/apache2 restart'
    end
  end

  desc 'Stop apache'
  task :'stop' do
    on release_roles :app do
        execute :sudo, '/etc/init.d/apache2 stop'
    end
  end

  desc 'Start apache'
  task :'start' do
    on release_roles :app do
        execute :sudo, '/etc/init.d/apache2 start'
    end
  end
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
        output = capture :sudo, koha_script('koha-dump'), server.fetch(:koha_instance_name)
        database_dump_path, config_dump_path = output.lines[1..2].map { |line| line.split(' ').last }
        execute :sudo, :mkdir, '-p', 'data'
        execute :sudo, :mv, database_dump_path, File.join('data', 'database.sql.gz')
        execute :sudo, :mv, config_dump_path, File.join('data', 'config.tar.gz')
        # server.group??
        execute :sudo, :chown, "#{server.user}:#{server.user}", '-R', 'data'
      end
    end
  end

  #task :'stash-unstashed-database' do
  #  on release_roles(:app) do
  #    within current_path do
  #      if test('[ ! -f data/database.sql.gz ]')
  #        invoke 'koha:stash-database'
  #      end
  #    end
  #  end
  #end

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

  desc 'Apply any database updates required.'
  task :updatedb do
    on release_roles :app do |server|
      execute :sudo, koha_script('koha-shell'), '-c', release_path.join('installer/data/mysql/updatedatabase.pl'), server.fetch(:koha_instance_name)
    end
  end

  desc 'Rebuild Elasticsearch index.'
  task :'rebuild-elasticsearch' do
    on release_roles :app do |server|
      execute :sudo, koha_script('koha-shell'), '-c', release_path.join('misc/search_tools/rebuild_elastic_search.pl'), '-d', server.fetch(:koha_instance_name)
    end
  end
  #TODO restore/revert/import?
  #task :restore_database
  desc 'Run Koha Deploy migrations'
  task :'koha-deploy-migrate' do
    # Extract the first 10 digits if followed by "." or "_"
    revision_re = Regexp.new('^\d{10}(?=[._])')
    on release_roles :app do |server|
      # TODO: Sort out File.join or .join??
      migrations_dir = 'koha_deploy/migrations'
      within release_path.join(migrations_dir) do
        # Create migrations table
        execute :sudo,
          koha_script('koha-mysql'),
          server.fetch(:koha_instance_name),
          "< #{release_path.join('koha_deploy', 'migrations_schema.sql')}"

        # Get current migration revision
        current_migration_revision = capture(
          :sudo,
          koha_script('koha-mysql'),
          server.fetch(:koha_instance_name),
          '-e "SELECT revision FROM koha_deploy_migrations ORDER BY revision DESC LIMIT 1"',
          '-sN',
        )
        debug "Current revision is #{current_migration_revision}"

        extract_revision = ->(filename) do
          revision_re.match(filename)[0]
        end

        # Get pending migrations
        pending_migrations = capture(:ls, '-1', '-r')
          .lines
          .map(&:strip)
          .reject { |migration_file|
            if not revision_re === migration_file
              warn "Invalid migration filename \"#{migration_file}\""
              true
            else
              false
            end
          }
          .take_while { |migration_file| extract_revision.call(migration_file) != current_migration_revision }
          .reverse

        # Run pending migrations separately, one transaction per migration
        if not pending_migrations.empty?
          pending_migrations.each do |migration_file|
            sql = "START TRANSACTION;\n"
            sql += capture(:cat, migration_file) + "\n"
            sql += "INSERT INTO koha_deploy_migrations(revision, filename) VALUES('#{extract_revision.call(migration_file)}', '#{migration_file}');\n"
            sql += "COMMIT;\n"
            begin
              output = capture :sudo, koha_script('koha-mysql'), server.fetch(:koha_instance_name), '-e', Shellwords.escape(sql)
            rescue SSHKit::Command::Failed => e
              error "Migration \"#{migration_file}\" failed with the following message:\n#{e.message}"
              aborted_migrations = pending_migrations.drop_while { |m| m <= migration_file }
              if not aborted_migrations.empty?
                info "Aborting the following pending migration#{aborted_migrations.length > 1 ? 's' : ''}: #{aborted_migrations.join(', ')}"
              end
              break
            end
          end
        else
          info "No pending migrations found"
        end
      end
    end
  end

  desc 'Adjust scripts'
  task :'adjust-scripts' do
    on release_roles :app do |server|
      within koha_scripts_path.join('debian', 'scripts') do
        # TODO: unavailable.html?
        execute :ls,
          '| xargs -I{ sed -i',
          '-e "s/\/etc\/koha\/\(apache-shared[^.]*\.conf\)/\/etc\/apache2\/conf-available\/' + server.fetch(:koha_instance_name) + '\/\1/g"',
          '-e "s/\/usr\/share\/koha\/bin\/koha-functions.sh/' + koha_scripts_path.join('koha-functions.sh').to_s.gsub('/', '\/') + '/g"',
          '-e "s/\/usr\/share\/koha\/opac\/htdocs/' + release_path.join('koha-tmpl').to_s.gsub('/', '\/') + '/g"',
          '-e "s/\/usr\/share\/koha\/intranet\/htdocs/' + release_path.join('koha-tmpl').to_s.gsub('/', '\/') + '/g"',
          ## We do this since changing standard naming convention of Koha Apache configuration files (not anymore)
          # '-e "s/\/sites-available\/\(\$site\|\$instancename\|\$name\|\$instancefile\)\.conf/\/sites-available\/koha-deploy-\1\.conf/g"',
          "{"
      end
    end
  end

  desc 'Adjust koha configuration'
  task :'adjust-koha-conf' do
    on release_roles :app do |server|
      current_path_escaped = current_path.to_s.gsub('/', '\/')
      command = [
        'sed -i',
        '-e "s/<intranetdir>[^<]*<\/intranetdir>/<intranetdir>' + current_path_escaped + '<\/intranetdir>/g"',
        '-e "s/<opacdir>[^<]*<\/opacdir>/<opacdir>' + current_path_escaped + '\/opac<\/opacdir>/g"',
        '-e "s/<intrahtdocs>[^<]*<\/intrahtdocs>/<intrahtdocs>' + current_path_escaped + '\/koha-tmpl\/intranet-tmpl<\/intrahtdocs>/g"',
        '-e "s/<opachtdocs>[^<]*<\/opachtdocs>/<opachtdocs>' + current_path_escaped + '\/koha-tmpl\/opac-tmpl<\/opachtdocs>/g"',
        '-e "s/<includes>[^<]*<\/includes>/<includes>' + current_path_escaped + '\/koha-tmpl\/intranet-tmpl\/prog\/en\/includes<\/includes>/g"',
        # XSLT-paths etc
        '-e "s/[^\"]\+\/koha-tmpl\/intranet-tmpl\/\([^\"]\+\)/' + current_path_escaped + '\/koha-tmpl\/intranet-tmpl\/\1/g"',
        "/etc/koha/sites/#{server.fetch(:koha_instance_name)}/koha-conf.xml"
      ].join(' ')
      execute :sudo, 'bash -c', Shellwords.escape(command)
    end
  end

  desc 'Create Apache configuration for current release, assumes existing instance created with koha-create'
  # Rename adjust apache config
  task :'adjust-apache-conf' do
    on release_roles :app do |server|
      execute :sudo, 'mkdir', "-p /etc/apache2/conf-available/#{server.fetch(:koha_instance_name)}"
      # Assumes koha-create has been run
      # Remove with release since not needed?
      #TODO: :koha_instance_name should be sed-escaped
      # Weirdness ahead: need to run in subshell since sudo only applied to first command (sed), not redirection of output
      # Alternative (perhaps nicer) solution "sudo ... | sudo tee <output file> > /dev/null

      # Use apache-shared* config files per koha instance, so replace all paths to point to these files instead
      command = [
        'sed -i',
        '-e "s/[^ ]\+\/\(apache-shared[^.]*\.conf\)/\/etc\/apache2\/conf-available\/' + server.fetch(:koha_instance_name) + '\/\1/g"',
        "/etc/apache2/sites-available/#{server.fetch(:koha_instance_name)}.conf"
      ].join(' ')
      execute :sudo, 'bash -c', Shellwords.escape(command)

      current_path_escaped = current_path.to_s.gsub('/', '\/')
      #TODO: setting for setting MOJO_MODE to something else than "production"?
      intranet_opac_common = [
        's/DocumentRoot [^ ]\+/DocumentRoot ' + current_path_escaped + '\/koha-tmpl/g',
        's/\(ScriptAlias [^ ]\+\) "[^"]\+\/cgi-bin\/\([^"]*\)"/\1 "' + current_path_escaped + '\/\2"/g',
        's/\/usr\/share\/koha\/api/'+ current_path_escaped + '\/api/g'
      ]
      apache_shared_files = {
        'apache-shared.conf' => ['s/SetEnv PERL5LIB "[^"]\+"/SetEnv PERL5LIB "' + current_path_escaped + '"/g'],
        'apache-shared-disable.conf' => [],
        'apache-shared-intranet.conf' => [*intranet_opac_common],
        'apache-shared-intranet-plack.conf' => [],
        'apache-shared-opac.conf' => [*intranet_opac_common],
        'apache-shared-opac-plack.conf' => []
      };
      apache_shared_files.each do |file, sed_expressions|
        source_file_path = File.join('/etc/koha', file)
        destination_file_path = File.join('/etc/apache2/conf-available', server.fetch(:koha_instance_name), file)
        puts [
              'sed',
              sed_expressions.map { |e| '-e \'' + e + '\'' }.join(' '),
              "\"#{source_file_path}\" > \"#{destination_file_path}\""
            ].join(' ')
        if not sed_expressions.empty?
          execute(:sudo,
            'bash -c',
            Shellwords.escape([
              'sed',
              sed_expressions.map { |e| '-e \'' + e + '\'' }.join(' '),
              "\"#{source_file_path}\" > \"#{destination_file_path}\""
            ].join(' '))
          )
        else
          # Just copy the file
          execute :sudo, "cp \"#{source_file_path}\" \"#{destination_file_path}\""
        end
      end
      # Update plack.psgi from latest release
      execute :sudo,
        'cp',
        release_path.join('debian', 'templates', 'plack.psgi'),
        File.join('/etc/koha/sites', server.fetch(:koha_instance_name), 'plack.psgi')
    end
  end

  # @TODO?
  #desc 'Perform post package installation setup tasks'
  #task :'post-package-install-fix' do
  #  on release_roles :app do
  #  end
  #end

  desc 'Sync Koha Deploy instance data'
  task :'koha-deploy-sync-managed-data' do
    meta_defaults = {
      'update' => true,
      'insert' => true,
    }
    get_filepath = ->(data_item) {
      if data_item['directory']
        File.join(data_item['directory'], data_item['filename'])
      else
        data_item['path']
      end
    }
    on release_roles :app do |server|
      within release_path.join('koha_deploy') do
        output = capture :cat, 'managed_data.yaml'
        managed_data = YAML.load(output)
        # Possible stage specific override
        stage_managed_data_filename = "managed_data/#{fetch(:stage)}.yaml"
        if test " [ -f #{stage_managed_data_filename} ] "
          output = capture :cat, stage_managed_data_filename
          stage_managed_data = YAML.load(output)
          managed_data.deep_merge!(stage_managed_data)
        end

        #@TODO: This SQL could become a monster, passing on command line still ok?
        sql = "START TRANSACTION;\n"
        #@TODO: perhaps break out most parts of this in separate helper class
        managed_data.each do |table, data_info|
          # Deep copy of meta_defaults
          root_meta = Marshal.load(Marshal.dump(meta_defaults))
          if data_info.key?('__meta__')
            root_meta.deep_merge!(data_info['__meta__'])
          end

          data_info['items'].each do |data_item|
            # Deep copy of root_meta
            meta = Marshal.load(Marshal.dump(root_meta))
            if data_item.key?('__meta__')
              meta.deep_merge!(data_item['__meta__'])
            end
            # Expand data entity column values
            # @TODO: In ruby > 2.8 data_entity.values is safe, assume modern ruby version?
            # TODO: Lots of validation and safety
            data = {}
            data_item.except('__meta__').each do |column, value|
              if value.is_a?(Hash)
                if value.key?('source')
                  if value['source'] == 'local_file'
                    filepath = get_filepath.call(value)
                    data[column] = File.read(filepath)
                  elsif value['source'] == 'release_file'
                    filepath = get_filepath.call(value)
                    # TODO: make sure no extra whitespace is added
                    output = capture :cat, release_path.join(filepath)
                    data[column] = output
                  elsif value['source'] == 'shared_file'
                    filepath = get_filepath.call(value)
                    # TODO: make sure no extra whitespace is added
                    output = capture :cat, shared_path.join(filepath)
                    data[column] = output
                  else
                    raise "Invalid source trlalala"
                  end
                else
                  raise "Missing source tralala..."
                end
              else
                data[column] = value
              end
            end

            #sql_variables = {}
            #data.values.each_with_index do |i, value|
            #  sql_variables["@var_#{i}"] = value
            #end

            # TODO: Here we assume keys exist, perhaps validation?
            # also presently no validation keys are correct

            sql_noop_query = "SELECT #{(['?'] * data.length).join(', ')}"
            sql_insert_query = nil
            if meta['insert']
              # Insert query
              sql_insert_query = "INSERT INTO #{table}(#{data.keys.map {|c| "`#{c}`"}.join(', ')}) VALUES("
              #sql_insert_query += data.values.map { |value| "'#{mysql_escape(value)}'" }.join(', ')
              sql_insert_query += (['?'] * data.length).join(', ')
              sql_insert_query += ")"
            else
              sql_insert_query = sql_noop_query
            end

            # Update condition
            sql_update_condition = meta['keys'].map do |column|
              "`#{column}` = '#{mysql_escape(data[column])}'"
            end.join(' AND ')

            # Update query
            sql_update_query = nil
            if meta['update']
              sql_update_query = "UPDATE #{table} SET "
              # TODO: fix duplicate code
              sql_update_query += data.keys.map do |column|
                #"`#{column}` = '#{mysql_escape(data[column])}'"
                "`#{column}` = ?"
              end.join(', ')
              sql_update_query += " WHERE #{sql_update_condition}"
            else
              # Noop
              sql_update_query = sql_noop_query
            end

            # TODO: Double escape, brain hurts, test
            # Alternative: replace " with ""
            # Alternative 2: mysql QUOTE?
            sql += <<-HEREDOC
              SET @sql = (SELECT IF(
                (SELECT COUNT(*)
                  FROM #{table} WHERE #{sql_update_condition}
                ) > 0,
                "#{mysql_escape(sql_update_query)};",
                "#{mysql_escape(sql_insert_query)};"
              ));
              #{data.values.each_with_index.inject('') { |output, (value, i)| output + "\nSET @var#{i} = \"#{mysql_escape(value)}\";" }}
              PREPARE stmt FROM @sql;
              EXECUTE stmt USING #{(0...data.length).to_a.map { |i| "@var#{i}" }.join(', ')};
              DEALLOCATE PREPARE stmt;
HEREDOC
          end
        end
        sql += "COMMIT;\n"
        # TODO: Rescue
        execute :sudo, koha_script('koha-mysql'), server.fetch(:koha_instance_name), '-e', Shellwords.escape(sql)
      end
    end
  end

  desc 'Setup instance (adjust apache configuration and koha-conf.xml)'
  task :'setup-instance' do
      on release_roles :app do
        invoke 'koha:adjust-apache-conf'
        invoke 'koha:adjust-koha-conf'
        invoke 'apache:restart'
      end
  end

  desc 'Run koha-enable'
  task :'enable' do
      on release_roles :app do |server|
        execute :sudo, koha_script('koha-enable'), server.fetch(:koha_instance_name)
      end
  end

  desc 'Run koha-disable'
  task :'disable' do
      on release_roles :app do
        execute :sudo, koha_script('koha-enable'), server.fetch(:koha_instance_name)
      end
  end

  desc 'Run koha-list'
  task :'list' do
      on release_roles :app do
        puts (capture :sudo, koha_script('koha-list'))
      end
  end

  desc 'Enter interactive MySQL shell'
  task :'mysql' do
    on roles(:app), :primary => true do |server|
      execute_interactively(server, "sudo #{koha_script('koha-mysql')} #{server.fetch(:koha_instance_name)}")
    end
  end

end

namespace :deploy do
  #after :starting, :backup_previous_revision_database do
  #  if fetch(:previous_revision)
  #    invoke 'koha:stash-database'
  #  end
  #end
  before :publishing, 'koha:adjust-scripts'
  # Enable maintenance mode
  after :publishing, 'koha:disable'
  after :publishing, 'koha:clear-cache'
  after :publishing, 'koha:updatedb'
  after :publishing, 'koha:koha-deploy-migrate'
  after :publishing, 'koha:koha-deploy-sync-managed-data'
  # Disable maintenance mode
  after :publishing, 'koha:enable'
end
