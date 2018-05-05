require 'shellwords'
require 'yaml'
require 'uri'
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
# file 'data/value_sources' do
#  mkdir('data/value_sources')
# end

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

  desc 'Adjust package installation scripts to use corresponding instance specific release scripts when run if possible'
  task :'adjust-package-installation-scripts' do
    adjust_package_script = <<-'HEREDOC'
my $script = q(
## BEGIN KOHA-DEPLOY
if [ $# -ge 1 -a -f "/etc/koha/sites/$1/koha-conf.xml" ]; then
  koha_root="$( xmlstarlet sel -t -v 'yazgfs/config/intranetdir' /etc/koha/sites/$1/koha-conf.xml )"
  release_script="$koha_root/debian/scripts/$0"
  if [ -f "$release_script" ]; then
    exec "$release_script" "$@"
  fi
fi
## END KOHA-DEPLOY
);
s{(^#!/bin/((bash)|(sh)))\s+(## BEGIN KOHA-DEPLOY.+?## END KOHA-DEPLOY\s)?}{$1$script}s;
HEREDOC
    on release_roles :app do |server|
      #@TODO: helpers
      tmp_script_file = File.join('/tmp/', "adjust_package_script_#{SecureRandom.urlsafe_base64}.pl")
      upload! StringIO.new(adjust_package_script), tmp_script_file
      execute :sudo, 'bash -c',
        Shellwords.escape("ls /usr/sbin/koha-* | xargs perl -0777 -i -p #{tmp_script_file}")
    end
  end

  desc 'Undo modifications to package installation scripts'
  task :'adjust-package-installation-scripts-undo' do
    on release_roles :app do |server|
      execute :sudo, 'bash -c', Shellwords.escape([
        'ls /usr/sbin/koha-* | xargs perl -0777 -i -p',
        '-e \'s{## BEGIN KOHA-DEPLOY.+?## END KOHA-DEPLOY\s}{}s\''
      ].join(' '))
    end
  end

  desc 'Adjust scripts'
  task :'adjust-scripts' do
    on release_roles :app do |server|
      within koha_scripts_path do
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

      # Special case for apache-shared.conf
      destination_file_path = File.join('/etc/apache2/conf-available', server.fetch(:koha_instance_name), 'apache-shared.conf')
      # Append "Require all granted"
      additional_conf = <<-HEREDOC
<IfVersion >= 2.4>
  <Directory "#{current_path}">
    Require all granted
  </Directory>
</IfVersion>
HEREDOC
      execute :sudo, 'bash -c', Shellwords.escape("echo #{Shellwords.escape(additional_conf)} >> #{destination_file_path}")
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

  desc "Build SQL-script from managed YAML data"
  #TODO: Option for local data_path?
  #TODO: Support either dir or direct path to yaml file??
  task :'stage-managed-data', :remote_data_path do |t, args|
    staged_sql = nil;
    on release_roles :app do |server|
      if staged_sql
        error "Multiple release roles for managed data not supported"
        exit 1
      end
      # TODO: remote_data_path validation?
      # remote_data_root?
      remote_data_path = args[:remote_data_path] ? Pathname.new(args[:remote_data_path]) : release_path.join('koha_deploy')
      managed_data = {}
      within remote_data_path do
        # Helper?
        managed_data_files = []
        begin
          managed_data_files = capture(:ls, '-1 2>/dev/null', remote_data_path.join('managed_data', '*.yaml'))
            .lines
            .map(&:strip)
            .sort
        rescue SSHKit::Command::Failed => e
          # ls with throw exception if no file matches, ignore
          info "No managed data yaml-files found in \"#{remote_data_path.join('managed_data')}\"."
        end

        stage_managed_data_dir = remote_data_path.join('managed_data', fetch(:stage).to_s);
        # Possible stage specific managed data
        if test " [ -d '#{stage_managed_data_dir}' ] "
          begin
            managed_data_files += capture(:ls, '-1 2>/dev/null', File.join(stage_managed_data_dir, '*.yaml'))
              .lines
              .map(&:strip)
              .sort
          rescue SSHKit::Command::Failed => e
            info "No managed data yaml-files found for stage \"#{fetch(:stage)}\" found in \"#{stage_managed_data_dir}\"."
          end
        end
        next if managed_data_files.empty?

        managed_data_files.each do |file_path|
          data = koha_yaml(file_path)
          managed_data.deep_merge!(data)
        end
      end
      staged_sql = managed_data_to_sql(managed_data, remote_data_path, args[:remote_data_path]) unless managed_data.empty?
    end
    if staged_sql
      run_locally do
        sql_output_path = koha_deploy_data_path.join('managed_data.sql')
        File.open(sql_output_path, 'w') { |file| file.write(staged_sql) }
        info "Generated SQL-script written to \"#{sql_output_path}\"."
      end
    end
  end

  desc "Load staged managed SQL-file"
  task :'load-managed-data', :local_file_path do |t, args|
    invoke 'koha:load-sql', args[:local_file_path] || 'managed_data.sql'
  end

  desc "Load SQL-file"
  task :'load-sql', :local_file_path do |t, args|
    on release_roles :app do |server|
        staged_file_path = nil
        if args[:local_file_path]
          staged_file_path = Pathname.new(args[:local_file_path])
          if staged_file_path.relative?
            staged_file_path = koha_deploy_data_path.join(args[:local_file_path])
          end
        else
          # Is there a way in capistrano to declare required argument?
          # TODO: Check source code for this
          error 'Task argument [local_file_path] is required.'
          exit 1
        end
        assert_local_file_exists(staged_file_path)
        tmp_sql_file = File.join('/tmp/', "koha_sync_data_#{SecureRandom.urlsafe_base64}.sql")
        upload! staged_file_path.to_s, tmp_sql_file
        # TODO: Rescue
        execute :sudo, koha_script('koha-mysql'), server.fetch(:koha_instance_name), "< '#{tmp_sql_file}'"
    end
  end

  desc "Sync managed instance data"
  task :'sync-managed-data', :remote_data_path do |t, args|
    invoke 'koha:stage-managed-data', args[:remote_data_path]
    invoke 'koha:load-managed-data'
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
      on release_roles :app do |server|
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
    on roles(:app) do |server|
      execute_interactively(server, "sudo #{koha_script('koha-mysql')} #{server.fetch(:koha_instance_name)}")
    end
  end

  desc 'Enter interactive Koha shell'
  task :'shell' do
    on roles(:app) do |server|
      execute_interactively(server, "sudo #{koha_script('koha-shell')} #{server.fetch(:koha_instance_name)}")
    end
  end

  desc 'Adjust permissions'
  task :'adjust-permissions' do
    on roles(:app) do |server|
      execute :sudo, "chown -R '#{server.user}:#{server.fetch(:koha_instance_name)}-koha' '#{release_path}'"
      execute :sudo, "chmod -R g+w '#{release_path}/koha-tmpl'"
    end
  end

  desc 'Install plugins'
  task :'plugins-install' do
    on roles(:app) do |server|
      plugins_dir = Pathname.new(koha_conf(server.fetch(:koha_instance_name), 'pluginsdir'))
      execute :sudo, "find '#{plugins_dir}' -mindepth 1 -delete"

      koha_deploy_dir = plugins_dir.dirname.join('koha_deploy')
      #execute :sudo, :mkdir, '-p', koha_deploy_dir
      plugin_repos_dir = koha_deploy_dir.join('plugin_repos')
      execute :sudo, :mkdir, '-p', plugin_repos_dir
      #tmp_dir = koha_deploy_dir.join('tmp')
      #execute :sudo, :mkdir, '-p', tmp_dir
      plugins_file = release_path.join('koha_deploy', 'plugins.yaml')
      if test "[ -f '#{plugins_file}' ]"
        plugins = koha_yaml(plugins_file)
        plugins.each do |plugin|
          repo_name = URI(plugin['url']).path.split('/').last
          repo_dir = plugin_repos_dir.join(repo_name)
          if test "[ -f '#{repo_dir.join('HEAD')}' ]"
            info "Plugin repository for #{plugin['url']} is at #{repo_dir}"
            within repo_dir do
              # Update the origin URL in case changed.
              execute :sudo, 'git', 'remote', 'set-url', 'origin', plugin['url']
              execute :sudo, 'git', 'remote', 'update', '--prune'
            end
          else
            execute :sudo, 'git', 'clone', '--mirror', plugin['url'], repo_dir
          end
          # Archive to plugin directory
          execute :sudo, 'bash -c', Shellwords.escape([
            "cd #{repo_dir};", 'git', 'archive', plugin['branch'], 'Koha', '| tar -x -f - -C', plugins_dir
          ].join(' '))
        end
      end
      # @TODO: Deploy info log
    end
  end

  desc 'Setup local repo'
  task :'setup-local-repo' do
    run_locally do
      if test(" [ -d #{File.join(koha_deploy_repo_path, '.git')} ] ")
        info "The local Koha repository is at #{koha_deploy_repo_path}"
        within koha_deploy_repo_path do
          execute :git, 'remote', 'set-url', 'origin', fetch(:repo_url)
          existing_remotes = capture(:git, 'remote')
            .lines
            .map(&:strip)
          fetch(:repo_remotes, {}).each do |remote, url|
            if existing_remotes.include?(remote)
              execute :git, 'remote', 'set-url', remote, url
            else
              execute :git, 'remote', 'add', remote, url
            end
          end
          if fetch(:repo_remotes, false)
            execute :git, 'fetch', '--all'
          end
          current_branch = capture(:git, 'rev-parse', '--abbrev-ref', 'HEAD')
            .strip
          if current_branch == fetch(:koha_deploy_release_branch_start_point)
            execute :git, 'pull'
          end
        end
      else
        within koha_deploy_repo_path do
          execute :git, 'clone', fetch(:repo_url), '.'
        end
      end
    end
  end

  namespace :'build' do

    desc 'Clean current build state'
    task :'clean' do
      run_locally do
        build_state_path = koha_deploy_build_state_path
        if File.file?(build_state_path)
          build_state = YAML.load(File.read(build_state_path))
          within koha_deploy_repo_path do
            # FIXME: Helper?
            if capture(:git, 'status') =~ /^rebase in progress;/
              info "Rebase in progress, aborting."
              execute :git, 'rebase', '--abort'
            end
            execute :git, 'checkout', fetch(:koha_deploy_release_branch_start_point)
            info "Deleting build branch."
            execute :git, 'branch', '-D', build_state['branch']
          end
          info "Deleting build state."
          execute :rm, build_state_path
        else
          info 'Build state not found, nothing to do.'
        end
      end
    end

    desc 'Clean current build state and build'
    task :'build-clean', [:branch_name, :branches_prefix, :branches_filter] => [:'clean', :'build']

    # TODO: Add remote?
    desc 'Build'
    task :'build', [:branch_name, :branches_prefix, :branches_filter] => :'setup-local-repo' do |t, args|
      run_locally do
        build_state_path = koha_deploy_build_state_path
        within koha_deploy_repo_path do
          #TODO: Set default value capistrano 3 way!
          if capture(:git, 'status') =~ /^rebase in progress;/
            # TODO: Fix message
            error "Rebase is in progess, please resolve any possible conflicts, stage files and run `git rebase --continue`"
            exit 1
          end

          build_state = {}
          # Commit helper
          build_state_commit = lambda do
            File.open(build_state_path, 'w') { |file| file.write(build_state.to_yaml) }
          end
          # Delete helper
          build_state_delete = lambda do
            build_state = {}
            FileUtils.rm(build_state_path)
          end
          release_branch = nil
          current_branch = capture(:git, 'rev-parse', '--abbrev-ref', 'HEAD')
            .strip
          start_point = fetch(:koha_deploy_release_branch_start_point)
          # Recover saved build state from aborted build
          rebase_branches = koha_deploy_rebase_branches(args[:branches_prefix], args[:branches_filter])
          if File.file?(build_state_path)
            build_state = YAML.load(File.read(build_state_path))
            # Validate build state
            unless build_state
              error "Empty build state, deleting."
              build_state_delete.call
              exit 1
            end
            unless build_state['branch'] && current_branch == build_state['branch']
              ## TODO: Prompt!?
              error "Current branch '#{current_branch}' is not the expected release branch '#{build_state['branch']}', please delete build state; `rm #{build_state_path}`, or checkout start point; `git checkout #{start_point}`."
              exit 1
            end
            release_branch = build_state['branch']
            rebase_branches -= build_state['rebase_branches_done'] || []
            info "Resume building branch '#{release_branch}'."
          else
            # No rebase in progress, make sure synced against origin
            # by deleting and re-adding all local rebase branches
            invoke 'koha:branches:checkout', args[:branches_prefix], args[:branches_filter]
            # TODO: Callback/fetch for suffix instead of hard coded time
            release_branch = args[:branch_name] || fetch(:koha_deploy_release_branch_prefix, 'release') + Time.now.strftime('%Y%m%d-%H%M')
            execute :git, 'checkout', '-b', release_branch, start_point
            info "Start building branch '#{release_branch}'."
            # Make sure build state file exists
            # TODO: Can this be removed?
            File.open(build_state_path, 'w') {}
            build_state['branch'] = release_branch
            build_state['rebase_branches_done'] = []
            build_state_commit.call
          end

          rebase_branches.each do |branch|
            info "Rebasing on '#{branch}'."
            rebase_continue = false
            while true
              begin
                if !rebase_continue
                  # TODO: Change to execute
                  output = capture :git, 'rebase', branch
                else
                  output = capture :git, 'rebase', '--continue'
                end
                # No conflicts or other errors, break loop
                break;
              rescue SSHKit::Command::Failed => e
                #TODO: begin resque that deletes build state and current build on hard crash?
                if /^CONFLICT / === e.message
                  # TODO: redundant, refactor?
                  output = capture :git, 'status'
                  if /^Unmerged paths:/ === output
                    # TODO: Expect this loop iteration to be manually resolved by the user,
                    # hence the branch should be integrated when we get here the next time
                    build_state['rebase_branches_done'] << branch
                    build_state_commit.call
                    error "You have unresolved conflicts in release branch '#{release_branch}', please resolve these conflicts, run `git rebase --continue`, then run koha:build-release-branch again."
                    exit 1
                  else
                    # We have a conflict, but it has probably been resolved and auto-staged using git rerere
                    # Try `git rebase --continue` and let it crash and burn if fails on anything else
                    # but a new conflict.
                    # On success we should be back on track and we break out of the loop.
                    info "Encountered merge conflict, but seems to have been resolved using previous solution."
                    rebase_continue = true
                  end
                else
                  # Unknown error, bail out
                  raise e
                end
              end
            end
            build_state['rebase_branches_done'] << branch
            build_state_commit.call
          end
          execute :git, 'checkout', start_point
          info "New release branch '#{release_branch}' is done."
          build_state_delete.call
        end
      end
    end

  end

  desc 'Build (alias)'
  task :'build', [:branch_name, :branches_prefix, :branches_filter]  => 'build:build'

  # @TODO: Possible to have task dependency on namespace level?
  namespace :'branches' do

    desc "List rebase branches"
    task :'branches', :'prefix', :'filter' do |t, args|
      # TODO: Extend in Capfile with local DSL to not have to run_locally
      run_locally do
        koha_deploy_rebase_branches(args[:'prefix'], args[:'filter']).each do |branch|
          puts branch
        end
      end
    end

    desc "Rebase rebase branches"
    task :'rebase', [:'prefix', :'upstream', :'filter'] => :'setup-local-repo' do |t, args|
      upstream = args[:'upstream'] || 'master'
      run_locally do
        within koha_deploy_repo_path do
          koha_deploy_rebase_branches(args[:'prefix'], args[:'filter']).each do |branch|
            execute :git, 'rebase', upstream, branch
          end
          execute :git, 'checkout', fetch(:koha_deploy_release_branch_start_point)
        end
      end
    end

    desc "Checkout rebase branches"
    task :'checkout', [:'prefix', :'filter', :'remote'] => :'setup-local-repo' do |t, args|
      invoke 'koha:branches:delete', args[:'prefix'], args[:'filter']
      remote = args[:'remote'] || 'origin'
      run_locally do
        within koha_deploy_repo_path do
          koha_deploy_rebase_branches(args[:'prefix'], args[:'filter']).each do |branch|
            execute :git, 'branch', '--track', branch, "remotes/#{remote}/#{branch}"
          end
        end
      end
    end

    desc "Push rebase branches"
    task :'push', [:'prefix', :'filter', :'remote', :'push_options'] => :'setup-local-repo' do |t, args|
      run_locally do
        within koha_deploy_repo_path do
          koha_deploy_rebase_branches(args[:'prefix'], args[:'filter']).each do |branch|
            # --set-upstream problematic if wanting to push same branches to multiple remotes?
            execute :git, 'push', args[:'push_options'] || '', '--set-upstream', args[:'remote'] || 'origin', "#{branch}"
          end
        end
      end
    end

    # Rename Checkout copy, checkout rename?
    desc "Copy rebase branches"
    task :'copy', [:'from_prefix', :'to_prefix', :'filter', :'from_remote'] => :'setup-local-repo' do |t, args|
      run_locally do
        unless args[:'to_prefix']
          error 'Task arguments [from_prefix,to_prefix] are required.'
          exit 1
        end
        invoke 'koha:branches:delete', args[:'to_prefix']

        from_prefix = args[:'from_prefix'] || ''
        from_remote = args[:'from_remote'] || 'origin'
        within koha_deploy_repo_path do
          koha_deploy_rebase_branches('', args[:'filter']).each do |branch|
            to_branch = args[:'to_prefix'] + branch
            execute :git, 'branch', '--no-track', to_branch, "remotes/#{from_remote}/#{from_prefix + branch}"
          end
        end
      end
    end

    desc "Delete local rebase branches"
    task :'delete', [:'prefix', 'filter'] => :'setup-local-repo'  do |t, args|
      run_locally do
        # Delete existing branches
        within koha_deploy_repo_path do
          (
            koha_deploy_local_branches &
            koha_deploy_rebase_branches(args[:'prefix'], args[:'filter'])
          ).each do |branch|
            execute :git, 'branch', '-D', branch
          end
        end
      end
    end

    # TODO: "Delete remote rebase branches"
  end

  desc 'List rebase branches (alias)'
  task :'branches', [:prefix, :filter]  => 'branches:branches'

  desc 'Install swedish language files and create templates.'
  task :'install-swedish-language' do
    on roles(:app) do |server|
      execute :sudo, 'koha-translate', '--install sv-SE', "-d #{server.fetch(:koha_instance_name)}"
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
  before :publishing, 'koha:plugins-install'
  # Enable maintenance mode
  after :publishing, 'koha:disable'
  after :publishing, 'koha:clear-cache'
  after :publishing, 'koha:updatedb'
  after :publishing, 'koha:koha-deploy-migrate'
  after :publishing, 'koha:install-swedish-language'
  # This is probably not needed, and could perhaps be removed
  # TODO: Default setting for koha user name?
  after :publishing, 'koha:adjust-permissions'
  # Disable maintenance mode
  after :publishing, 'koha:enable'
end
