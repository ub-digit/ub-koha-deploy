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
set :branch, 'release-2020.02-20200427.1257'

set :koha_deploy_branches_prefix, ''
set :koha_deploy_release_branch_prefix, 'release-2020.02-'
set :koha_deploy_release_branch_start_point, 'koha-build-master'

set :koha_deploy_rebase_branches, [
  'gub-bug-14957-marc-permissions',
  'gub-bug-18129-staged-imports-user-filter',
  'gub-bug-18138-marc-modification-template-on-biblio-save',
  'gub-bug-19197-elasticsearch-wrong-operator-case',
  'gub-bug-19707-elasticsearch-sync-mappings-work',
  'gub-bug-25539-remove-defer-marc-save',
  'bulkmarcimport',
  'gub-dev-remove-lost-item-refund-msg',
  'gub-dev-koha-svc',
  'gub-dev-opac-simplified-messaging',
  'gub-dev-withdrawn-status-details',
  'gub-dev-bypass-confirmation-notforloan-status',
  'gub-overdue-messaging',
  'gub-plugin-extender',
  'gub-dev-acquisitions-fixes',
  'gub-dev-syspref-autoapprove-user-profile',
  'gub-dev-sip-send-location-code',
  'gub-dev-sip-no-alert-for-available',
  'gub-dev-frontend-assets',
  'gub-dev-KOHA-925-work',
  'gub-dev-advanced-search-customizations',
  'gub-dev-odue-debar-removal-fix',
  'gub-dev-auto-add-001',
  'gub-dev-callnumber-095-fallback',
  'gub-dev-prevent-ref-from-hold-resolve',
  'gub-dev-gub-format-facet',
  'gub-dev-circulation-reports',
  'gub-dev-extended-inhouse-loans',
  'gub-dev-message-queue-delay',
  'gub-dev-edifact-cron',
  'gub-dev-disable-hold-waiting-on-sip-return',
  'gub-bug-23009-deleted-marc-conditions',
  'gub-bug-20492-elasticsearch-adv-search-year-limit',
  'gub-dev-allow-issue-when-reserved',
  'gub-dev-cache-subscription-frequencies',
  'gub-change-sort-order-and-paging-for-table-subscription-numberpatterns',
  'gub-dev-opac-minalan',
  'gub-dev-show-852-in-biblio',
  'gub-dev-do-not-backdate-return-via-sip',
  'gub-dev-fromdate-in-fines',
### Fungerar ej längre men problemet den försöker lösa kvarstår  'gub-dev-change-accruing-fine-on-lost-pay',
  'gub-bug-20262-refund-fees-without-creating-credits',
  'gub-dev-fix-debarred_comment',
  'gub-dev-fix-unitprice-decimal',
  'gub-dev-owning-library-sender',
  'gub-dev-incomplete-barcode',
  'gub-bug-23548-aq-field-required',
  'gub-dev-allow-zero-in-phonenumber',
  'gub-dev-reset-expiration-on-revert',
  'gub-dev-plugin-hooks',
  'gub-dev-plugin-hooks-update-status',
  'gub-dev-syspref-plugin-hook',
  'gub-bug-22539-fines-calculation-fix',
  'gub-dev-sip-was-transferred-fix',
  'hides-dateofbirth-and-library-filters-from-patron-search',
  'gub-dev-sort-collation-sv',
  'move-code-from-js-to-tt-template',
  'gub-dev-hide-search-sort-options',
  'gub-dev-limit-visible-patron-notices',
  'gub-dev-acqusition-form-hide-unused-items',
  'gub-dev-mandatory-account-selection-in-acqusition',
  'gub-bug-24720-special-chars-normalize-sort-fields',
  'gub-dev-opac-hide-renew-functionality-when-not-applicable-m',
  'gub-bug-22771-nonfiling-characters-for-sort-fields',
  'gub-dev-acqui-handle-missing-biblio-in-orders',
  'gub-dev-prevent-accidental-removal-of-library-groups', ### Tillfällig lösning på bug, ska vara rättat i Koha
  'gub-dev-hide-fines-table-if-empty',
  'auto-renew-borrower-account-cron',
  'gub-bug-24456-incorrect-issues-sort-order',
  'gub-dev-intra-hide-revert-waiting-btn',
  'gub-dev-hide-editable-date-holds-table',
  'gub-dev-remove-clubs-from-tab-nav',
  'gub-bug-24788-remove-autoloaded-column-accessors',
  'gub-bug-24807-elasticsearch-sort-empty-values',
  'gub-dev-revert-total-calculation-from-23522',
  'gub-dev-barcode-librarycard',
  'gub-dev-cleaning-scripts',
  'gub-dev-pg-reports',
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
