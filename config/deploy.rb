## CAPISTRANO ##

# config valid only for Capistrano 3.1
#lock '3.2.1'

set :application, 'koha'
set :repo_url, 'https://github.com/ub-digit/Koha.git'
set :repo_remotes, {
  'koha-build' => 'git@github.com:ub-digit/Koha-build.git'
}

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call
set :branch, 'release-2020.02-20200211.1604'

set :koha_deploy_branches_prefix, ''
set :koha_deploy_release_branch_prefix, 'release-2020.02-'
set :koha_deploy_release_branch_start_point, 'koha-build-master'

set :koha_deploy_rebase_branches, [
  'gub-bug-14957-marc-permissions',
  'gub-bug-18129-staged-imports-user-filter',
  'gub-bug-18138-marc-modification-template-on-biblio-save',
  'gub-bug-19197-elasticsearch-wrong-operator-case',
  'gub-bug-19707-elasticsearch-sync-mappings-work',
  ## temporarly disable 'gub-bug-19884-faster-GetItem',
  'bulkmarcimport',
  'gub-dev-remove-lost-item-refund-msg',
  'gub-dev-koha-svc',
  'gub-dev-opac-simplified-messaging',
## löst i koha  'gub-dev-remove-cancel-button',
  'gub-dev-withdrawn-status-details',
  'gub-dev-bypass-confirmation-notforloan-status',
  'gub-overdue-messaging',
  'gub-plugin-extender',
### reservation error when enabled  'gub-disable-plugin-pagination',
  ## temporarly disabled 'queue_elastic_indexing',
  'gub-dev-acquisitions-fixes',
  'gub-dev-local-translation-files',
  'gub-dev-syspref-autoapprove-user-profile',
  'gub-dev-sip-send-location-code',
  'gub-dev-sip-no-alert-for-available',
  'gub-dev-frontend-assets',
  'gub-dev-KOHA-925-work',
  'gub-dev-advanced-search-customizations',
  'gub-dev-odue-debar-removal-fix',
  'gub-dev-auto-add-001',
  'gub-dev-callnumber-095-fallback',
  'gub-dev-restrict-history-tabs',
  'gub-dev-prevent-ref-from-hold-resolve',
  'gub-dev-gub-format-facet',
  'gub-dev-circulation-reports',
  'gub-bug-20334-elasticsearch-escape-query-slashes',
  'gub-dev-extended-inhouse-loans',
  'gub-dev-message-queue-delay',
  'gub-dev-edifact-cron',
  'gub-dev-disable-hold-waiting-on-sip-return',
### delvis löst i Koha  'stop-delete-patron-when-patron-has-holds', 
  'gub-bug-23009-deleted-marc-conditions',
  'gub-bug-20492-elasticsearch-adv-search-year-limit',
  #'gub-bug-20535-elasticsearch-ModZebra-stripped-items',
  'gub-dev-allow-issue-when-reserved',
  'gub-dev-cache-subscription-frequencies',
  'gub-change-sort-order-and-paging-for-table-subscription-numberpatterns',
  'gub-dev-opac-minalan',
  'gub-dev-show-852-in-biblio',
  #'gub-dev-revert-bug-11512-holdoverride',
  'gub-dev-do-not-backdate-return-via-sip',
  'gub-dev-fromdate-in-fines',
  'gub-dev-change-accruing-fine-on-lost-pay',
  'gub-bug-20262-refund-fees-without-creating-credits',
  'gub-dev-fix-debarred_comment',
  'gub-dev-fix-unitprice-decimal',
### tagits med i koha master  'gub-bug-20589-field-boosting',
  'gub-dev-owning-library-sender',
  'gub-dev-incomplete-barcode',
  'gub-bug-23548-aq-field-required',
### löst i koha  'temporary-fix-auth-values',
  'gub-dev-allow-zero-in-phonenumber',
  'gub-dev-reset-expiration-on-revert',
### löst i koha, syspref  'gub-dev-mana-enabled-js-workaround',
  'gub-dev-plugin-hooks',
  'gub-dev-plugin-hooks-update-status',
###  tagits med i koha master 'gub-bug-22592-support-for-index-scan',
  'gub-bug-23680-new-item-window-close',
  'gub-dev-syspref-plugin-hook',
### löst i koha  'gub-bug-23655-fix-about-page',
### löst i i koha  'gub-bug-23730-fix-export-of-reports',
  'gub-bug-22539-fines-calculation-fix',
  'gub-dev-sip-was-transferred-fix',
###  cherry-pickat commiter till gub-dev-koha-svc 'gukort2-development',
  'hides-dateofbirth-and-library-filters-from-patron-search',
  'gub-dev-sort-collation-sv',
  'move-code-from-js-to-tt-template',
  'gub-dev-hide-search-sort-options',
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
  misc/translator/po/sv-SE-staff-prog.po
  misc/translator/po/sv-SE-messages.po
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

if File.exists?(File.join(File.dirname(__FILE__), 'deploy.local.rb'))
  require_relative 'deploy.local.rb'
end
