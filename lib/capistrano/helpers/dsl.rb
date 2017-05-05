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
      end
    end
  end
end
