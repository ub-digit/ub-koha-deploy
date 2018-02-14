## CAPISTRANO ##

# config valid only for Capistrano 3.1
#lock '3.2.1'

set :application, 'koha'
set :repo_url, 'https://github.com/ub-digit/Koha.git'

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call
set :branch, 'release-20180214'

set :koha_deploy_release_branch_start_point, 'master'
set :koha_deploy_rebase_branches, [
  'bug_14957',
  'bug-18129',
  'bug-18138',
  'bug_19197',
  'bug_19564',
  'bug_19575',
  'bug_19707',
  #'bug_19819', # Bug 19819 - C4::Context->dbh is unreasonably slow
  'bug_19820',
  'bug_19884',
  'bulkmarcimport',
  'gub-dev-hide-ical-link',
  'gub-dev-hide-opac-search-and-links',
  'gub-dev-hide-syndetics-cover-images-opac',
  'gub-dev-koha-svc',
  'gub-dev-logo',
  'gub-dev-opac-personal-details-adjustements',
  'gub-dev-opac-redirect',
  'gup-dev-opac-holds-table-custom',
  'gub-dev-opac-simplified-messaging',
  'gub-dev-remove-cancel-button',
  'gub-dev-withdrawn-status-details',
  'gub-dev-bypass-confirmation-notforloan-status',
  'gub-overdue-messaging',
  'gub-plugin-extender',
  'gub-disable-plugin-pagination',
  'queue_elastic_indexing',
  'gub-dev-acquisitions-fixes',
  'gub-dev-local-translation-files',
  'gub-dev-syspref-autoapprove-user-profile',
  'gub-dev-sip-send-location-code',
  'gub-dev-sip-no-alert-for-available',
  'gub-dev-frontend-assets',
  'bug_20114',
  'bug_19893',
  'gub-dev-KOHA-925',
  'gub-dev-advanced-search-customizations',
  'gub-dev-odue-debar-removal-fix',
  'gub-dev-auto-add-001',
  'gub-dev-callnumber-095-fallback',
  'koha-deploy'
]
#set :koha_deploy_merge_branches, [
#  'koha-deploy',
#]

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/drupal/staging'

set :format, :pretty
set :log_level, :info

# Default false
set :pty, false
#set :pty, true

# set :linked_files, %w{web/sites/default/secret.settings.php web/sites/default/site.settings.php}
set :linked_files , %w{
  misc/translator/po/sv-SE-marc-MARC21.po
  misc/translator/po/sv-SE-marc-NORMARC.po
  misc/translator/po/sv-SE-marc-UNIMARC.po
  misc/translator/po/sv-SE-opac-bootstrap.po
  misc/translator/po/sv-SE-pref.po
  misc/translator/po/sv-SE-staff-help.po
  misc/translator/po/sv-SE-staff-prog.po
  misc/translator/po/sv-SE-local-opac-bootstrap.po
  misc/translator/po/sv-SE-local-staff-prog.po
}

# Default value for linked_dirs is []
# set :linked_dirs, %w{web/sites/default/files}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5

## KOHA DEPLOY ##
#set :koha_deploy_instance_settings_branch, 'koha-deploy'
#set :koha_deploy_instance_migrations_branch, 'koha-deploy'

## NPM ##
# set :npm_roles, :app
# set :npm_target_path, -> { release_path.join(fetch(:theme_path)) }
# set :npm_flags, '--silent --no-spin'
# set :npm_prune_flags, ''

namespace :deploy do
  before :starting, :set_command_map_paths do
    # Koha shell??
    #SSHKit.config.command_map[:composer] = "php #{shared_path.join("composer.phar")}"
  end

  before :starting, :site_settings do
    #on roles :app do
    #  template 'site.settings.php', shared_path.join(fetch(:site_path), 'site.settings.php'), 0644
    #end
  end
end
