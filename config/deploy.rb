## CAPISTRANO ##

# config valid only for Capistrano 3.1
#lock '3.2.1'

set :application, 'koha'
#set :repo_url, 'https://github.com/ub-digit/Koha.git'
set :repo_url, 'git@github.com:ub-digit/Koha-build.git'

set :repo_remotes, {
  'koha-build' => 'git@github.com:ub-digit/Koha-build.git'
}

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call
set :branch, 'release-2020.09-20210630.1325-hotfix-001'

set :koha_deploy_branches_prefix, ''
set :koha_deploy_release_branch_prefix, 'release-2022.02-'
set :koha_deploy_release_branch_start_point, 'koha-build-master'

set :koha_deploy_rebase_branches, [
#  'gub-bug-14957-marc-permissions-tmp', #med i master
  'gub-bug-18129-staged-imports-user-filter',
  'gub-bug-18138-marc-modification-template-on-biblio-save',
  'gub-bug-19707-elasticsearch-sync-mappings-work',
#  'gub-bug-25539-remove-defer-marc-save', #med i gub-bug-29440-25539-29597-29654-bulkmarcimport
#  'bulkmarcimport', #med i gub-bug-29440-25539-29597-29654-bulkmarcimport
  'gub-bug-29440-25539-29597-29654-bulkmarcimport',
  'gub-dev-remove-lost-item-refund-msg',
  'gub-dev-koha-svc',
  'gub-dev-simplified-messaging',
  'gub-overdue-messaging',
  'gub-plugin-extender',
#  'gub-dev-acquisitions-fixes', #delas upp i 2 följande
  'gub-dev-acquisitions-uncertain-price-on-importing',
  'gub-dev-acquisitions-recalculate-price',
  'gub-bug-20058-sip-send-location-code',
#  'gub-dev-favicon-for-my-loans', #obsolet
#  'gub-dev-css-for-slip-prints', #flyttas till statisk fil
  'gub-dev-set-focus-on-confirm-hold-and-transfer-button',
  'gub-dev-advanced-search-customizations',
  'gub-bug-29145-overdue-debarments-fix',
  'gub-dev-auto-add-001',
  'gub-dev-callnumber-095-fallback',
  'gub-dev-gub-format-facet',
  'gub-dev-circulation-reports',
  'gub-dev-extended-inhouse-loans',
  'gub-dev-edifact-cron',
  'gub-bug-20551-export-records-deleted',
  'gub-bug-23009-deleted-marc-conditions',
  'gub-dev-cache-subscription-frequencies',
  'gub-change-sort-order-and-paging-for-table-subscription-numberpatterns',
#  'gub-dev-opac-minalan', #obsolet
  'gub-dev-show-852-in-biblio',
#  'gub-dev-do-not-backdate-return-via-sip',
#  'gub-dev-fromdate-in-fines',
  'gub-bug-20262-refund-lost-only-if-unpaid',
  'gub-dev-fix-unitprice-decimal',
  'gub-dev-incomplete-barcode',
  'gub-bug-23548-aq-field-required',
#  'gub-dev-reset-expiration-on-revert',
  'gub-dev-plugin-hooks',
  'gub-dev-plugin-hooks-update-status',
  'gub-dev-hides-dateofbirth-and-library-filters-from-patron-search',
  'gub-dev-sort-collation-sv',
  'gub-dev-hide-checkout-history-button-in-biblio-view',
  'gub-dev-hides-circulation-history-and-holds-history-in-patron-post',
  'gub-dev-hides-last-returned-by-and-last-borrower-and-previous-borrower-in-item-view',
  'gub-dev-hides-pay-all-fines-button-in-patron-checkout-view',
  'gub-dev-hides-show-all-transactions-filter-button-in-borrower-accounting-view',
  'gub-dev-hide-patron-attributes',
  'gub-dev-adaptation-of-warning-message-when-deleting-bilio-if-biblio-has-an-order-post',
  'gub-dev-hide-search-sort-options',
  'gub-dev-limit-visible-patron-notices',
  'gub-dev-acqusition-form-hide-unused-items',
  'gub-dev-mandatory-account-selection-in-acqusition',
  'gub-bug-24720-special-chars-normalize-sort-fields',
#  'gub-dev-hide-fines-table-if-empty', #obsolet
  'auto-renew-borrower-account-cron',
  'gub-dev-intra-hide-revert-waiting-btn',
  'gub-dev-hide-editable-date-holds-table',
  'gub-dev-revert-total-calculation-from-23522',
  'gub-dev-cleaning-scripts',
  'gub-dev-online-payments',
  'gub-dev-pg-reports',
  'gub-dev-koha-1527-alphabetical-sorting-of-accounts',
  'gub-dev-koha-1545-set-permanent-location',
  'gub-dev-remove-tabs-from-make-payment',
#  'gub-dev-koha-1568-broken-filter-in-transactions', #verkar vara löst i master
#  'gub-bug-15775-maxoutstanding-alert', #obsolet
  'gub-bug-27859-marc-export-search-result',
  'gub-dev-set-default-biblio-in-orders-when-missing',
  'gub-dev-lost-status-update-for-paid-issues',
  'gub-dev-force-default-replacementcost',
  'gub-dev-allow-zero-vendor-id',
#  'gub-bug-koha-1614-email-html-fix', #löst i master
  'koha-1662-hide-existing-holds-priority-dropdown',
  'gub-dev-remove-graphics-magick-dep',
  'gub-update-permissions',
  'gub-dev-environment-assets',
#  'gub-dev-disable-regexp-replace-in-migration',
#  'gub-dev-disable-analytics-link', #kolla om detta är löst
  'gub-dev-cpanfile-version-specification',
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
  misc/translator/po/sv-SE-installer-MARC21.po
  misc/translator/po/sv-SE-installer.po
  misc/translator/po/sv-SE-marc-MARC21.po
  misc/translator/po/sv-SE-marc-NORMARC.po
  misc/translator/po/sv-SE-marc-UNIMARC.po
  misc/translator/po/sv-SE-opac-bootstrap.po
  misc/translator/po/sv-SE-pref.po
  misc/translator/po/sv-SE-staff-prog.po
  misc/translator/po/sv-SE-messages-js.po
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
