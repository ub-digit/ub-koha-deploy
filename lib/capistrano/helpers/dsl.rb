require 'yaml'

module Capistrano
  module KohaDeploy
    module Paths
      # TODO: change namespace to LocalPaths, or method names
      # to clarify these are local paths (not remote ones)
      def koha_deploy_path
        Pathname.new(Dir.pwd)
      end

      def koha_deploy_repo_path
        koha_deploy_path.join('repo')
      end

      def koha_deploy_data_path
        koha_deploy_path.join('data')
      end

      def koha_deploy_build_state_path
        koha_deploy_data_path.join('build_release_branch_state')
      end

      def assert_local_file_exists(filepath)
        unless File.exists?(filepath)
          error "File \"#{filepath}\" does not exist"
          exit
        end
      end
    end
    module Helpers
      module DSL
        def managed_data_to_sql(managed_data, data_path, data_path_overridden)
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
          #@TODO: This SQL could become a monster, passing on command line still ok?
          sql = "START TRANSACTION; SET FOREIGN_KEY_CHECKS = 0;\n"
          #@TODO: perhaps break out most parts of this in separate helper class
          managed_data.each do |table, data_info|
            # Deep copy of meta_defaults
            root_meta = Marshal.load(Marshal.dump(meta_defaults))
            if data_info.key?('__meta__')
              root_meta.deep_merge!(data_info['__meta__'])
            end

            if root_meta['truncate']
              sql += "TRUNCATE TABLE `#{table}`;\n"
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
                      file_data = File.read(filepath)
                      file_data.force_encoding('UTF-8')
                      data[column] = file_data
                    elsif value['source'] == 'release_file' # Change name since root is not release, but relative to managed data dir?
                      filepath = get_filepath.call(value)
                      # TODO: make sure no extra whitespace is added
                      # TODO: temporary hack, fix properly:
                      #if data_path_overridden
                      #  # Unshift "koha_deploy" part, temp hack
                      #  filepath = filepath.split(File::SEPARATOR)[1..-1].join(File::SEPARATOR)
                      #end
                      output = capture :cat, data_path.join(filepath)
                      output.force_encoding('UTF-8')
                      data[column] = output
                    elsif value['source'] == 'shared_file'
                      filepath = get_filepath.call(value)
                      # TODO: make sure no extra whitespace is added
                      # TODO: Superugly dry-run path hack, but it will have to do
                      path_root = data_path_overridden ? data_path.join('shared') : shared_path
                      output = capture :cat, path_root.join(filepath)
                      output.force_encoding('UTF-8')
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
                if data[column].kind_of?(Numeric)
                  "`#{column}` = #{data[column]}"
                else
                  "`#{column}` = '#{mysql_escape(data[column].to_s)}'"
                end
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
              #{data.values.each_with_index.inject('') { |output, (value, i)| output + "\nSET @var#{i} = #{value.kind_of?(Numeric) ? value : '"' + mysql_escape(value.to_s) + '"'};" }}
              PREPARE stmt FROM @sql;
              EXECUTE stmt USING #{(0...data.length).to_a.map { |i| "@var#{i}" }.join(', ')};
              DEALLOCATE PREPARE stmt;
              HEREDOC
            end
          end
          sql += "SET FOREIGN_KEY_CHECKS = 0; COMMIT;\n"
          return sql
        end

        # Stolen from https://github.com/tmtm/ruby-mysql
        def mysql_escape(str)
          str.gsub(/[\0\n\r\\\'\"\x1a]/) do |s|
            case s
            when "\0" then "\\0"
            when "\n" then "\\n"
            when "\r" then "\\r"
            when "\x1a" then "\\Z"
            else "\\#{s}"
            end
          end
        end

        def koha_scripts_path
          release_path.join('debian', 'scripts')
        end

        def koha_script(name)
          koha_scripts_path.join(name)
        end

        def koha_conf(instance_name, name)
          capture :sudo, "xmlstarlet sel -t -v 'yazgfs/config/#{name}' /etc/koha/sites/#{instance_name}/koha-conf.xml"
        end

        def execute_interactively(server, command)
          options = server.netssh_options
          keys = ((not options[:keys].nil?) and options[:keys].any?) ? "-i '#{options[:keys][0]}'" : ''
          puts "ssh -l #{options[:user]} #{server.hostname} -p #{options[:port]} #{keys} -t '#{command}'"
          exec "ssh -l #{options[:user]} #{server.hostname} -p #{options[:port]} #{keys} -t '#{command}'"
        end

        # TODO: Rename to something better?
        def koha_yaml(filepath)
          output = capture :cat, filepath
          YAML.load(output)
        end
      end

      # TODO: naming?
      module Local
        module DSL
          def koha_deploy_local_branches
            capture(:git, 'for-each-ref', 'refs/heads', "--format='%(refname:short)'")
              .lines
              .map(&:strip)
          end

          def koha_deploy_rebase_branches(prefix=nil, regexp_filter=nil)
            branches = _maybe_prefix(
              fetch(:koha_deploy_rebase_branches) || [],
              (prefix || '') + (fetch(:koha_deploy_branches_prefix, nil) || '')
            )
            if regexp_filter
              r = Regexp.new(regexp_filter)
              branches.select { |branch| branch =~ r }
            else
              branches
            end
          end

          def _maybe_prefix(items, prefix)
            prefix ? items.map { |item| prefix + item } : items
          end
        end
      end
    end
  end
end
