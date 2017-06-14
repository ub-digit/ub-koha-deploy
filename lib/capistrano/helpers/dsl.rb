module Capistrano
  module Template
    module Helpers
      module DSL
        def template_digest(path, digest_algo)
          fail ::ArgumentError, "template #{path} not found Paths: #{template_paths_lookup.paths_for_file(path).join(':')}" unless template_exists?(path)
          TemplateDigester.new(Renderer.new(template_paths_lookup.template_file(path), self), digest_algo).digest
        end

        def sha256_script_exec(script_abs_path, digest)
          "/bin/test \"$(sha256sum #{script_abs_path} | awk {'print $1'}) = \"#{digest}\" && #{script_abs_path}"
        end

        # TODO: Rename
        def sudoers_entry_as_s(user, digest, command_abs_path)
          SudoersEntry.new(user, digest, command_abs_path).render
        end

        # *args?
        # TODO: Command is path_to_script
        def sudoers_entry(user, digest, command_abs_path)
          StringIO.new(sudoers_entry_as_s(user, digest, command_abs_path))
        end

        class SudoersEntry
          attr_accessor :user, :digest, :command
          def initialize(user, digest, command)
            @user = user
            @digest = digest
            @command = command
          end
          def render
            ERB.new("<%= @user %> ALL=(ALL) NOPASSWD: <%= @digest %> <%= @command %>").result(binding)
          end
        end

        def drupal_deploy_prepare_script(script, remote_path)
          template script, remote_path.join(script), 0750
          digest = template_digest(script, ->(data){ Digest::SHA256.hexdigest(data) })
          entry = sudoers_entry('drupal-deploy', "sha256:#{digest}", "#{remote_path.join(script)}")
          upload! entry, remote_path.join('suduers-' + script.chomp('.sh'))
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

        def koha_yaml(filepath)
          output = capture :cat, filepath
          YAML.load(output)
        end
      end
    end
  end
end
