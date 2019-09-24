## CAPISTRANO ##

# config valid only for Capistrano 3.1
#lock '3.2.1'

set :application, 'koha'
set :repo_url, 'https://github.com/ub-digit/Koha.git'
set :repo_remotes, {
  'ub-digit' => 'git@github.com:ub-digit/Koha-build.git'
}

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call
set :branch, 'release-2019.09-20190918.1511'

set :koha_deploy_branches_prefix, ''
set :koha_deploy_release_branch_prefix, 'release-2019.09-'
set :koha_deploy_release_branch_start_point, 'koha-build-master'

set :koha_deploy_rebase_branches, [
  'gub-bug-14957-marc-permissions',
  'gub-bug-18129-staged-imports-user-filter',
  'gub-bug-18138-marc-modification-template-on-biblio-save',
  'gub-bug-19197-elasticsearch-wrong-operator-case',
  #'gub-bug-19564-elasticsearch-sort-condition',
  #'gub-bug-19575-elasticsearch-zebra-compatible-field-names',
  'gub-bug-19707-elasticsearch-sync-mappings-work',
  #'bug_19819', # Bug 19819 - C4::Context->dbh is unreasonably slow
  #'gub-bug-19820-GetMarcSubfieldStructure-unsafe-param',
  ## temporarly disable 'gub-bug-19884-faster-GetItem',
  'bulkmarcimport',
  'gub-dev-remove-lost-item-refund-msg',
  'gub-dev-koha-svc',
  'gub-dev-opac-simplified-messaging',
  'gub-dev-remove-cancel-button',
  'gub-dev-withdrawn-status-details',
  'gub-dev-bypass-confirmation-notforloan-status',
  'gub-overdue-messaging',
  'gub-plugin-extender',
  'gub-disable-plugin-pagination',
  ## temporarly disabled 'queue_elastic_indexing',
  'gub-dev-acquisitions-fixes',
  'gub-dev-local-translation-files',
  'gub-dev-syspref-autoapprove-user-profile',
  'gub-dev-sip-send-location-code',
  'gub-dev-sip-no-alert-for-available',
  'gub-dev-frontend-assets',
  ## Maybe solved by #20114 'gub-bug-20114-elasticsearch-facets-pagination',
  #'gub-bug-19893-elasticsearch-alternative-indexing-work',
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
  #'gub-bug-20356-email-sms-driver-from',
  #'gub-bug-20285-lost-items-fee',
  'gub-dev-extended-inhouse-loans',
  'gub-dev-message-queue-delay',
  'gub-dev-edifact-cron',
  #'gub-dev-fix-koha-1149',
  'gub-dev-disable-hold-waiting-on-sip-return',
  #'bug-fix-using-nonexistent-msg', # Now in koha master
  'stop-delete-patron-when-patron-has-holds',
  #'gub-bug-20251-sip-checkout',
  'gub-bug-20551-export-records-deleted',
  #'gub-bug-20486-export-records-marc-conditions', # Now in koha master
  'gub-bug-20492-elasticsearch-adv-search-year-limit',
  #'gub-bug-20167-pickup-location-keep-itemnumber',
  'gub-bug-20535-elasticsearch-ModZebra-stripped-items',
  #'gub-bug-20485-export-records-items-timestamp',
  'gub-dev-allow-issue-when-reserved',
  'gub-dev-cache-subscription-frequencies',
  'gub-change-sort-order-and-paging-for-table-subscription-numberpatterns',
  'gub-dev-opac-minalan',
  'gub-dev-show-852-in-biblio',
  #'gub-bug-20792-fix-patron-edit-page',
  'gub-dev-revert-bug-11512-holdoverride',
  'gub-dev-do-not-backdate-return-via-sip',
  'gub-dev-fromdate-in-fines',
  #'gub-bug-20972-edifact-isbn-fix',
  'gub-dev-change-accruing-fine-on-lost-pay',
  'gub-bug-20262-refund-fees-without-creating-credits',
  #'gub-bug-19687-undefined-subroutine',
  #'gub-bug-21462-filter-paid-transactions-fix',
  #'gub-bug-21471-fix-_getoutstanding_holds',
  'gub-dev-fix-debarred_comment',
  'gub-dev-fix-unitprice-decimal',
  #'gub-bug-21471-misspelled-items',
  #'gub-dev-remove-html-filter', # ta bort branch, finns nu i koha ($raw)
  'gub-bug-20589-field-boosting',
  'gub-dev-owning-library-sender',
  # 'gub-dev-intranet-auth-cas-fix',
  'gub-dev-incomplete-barcode',
  'gub-bug-23548-aq-field-required',
  'temporary-fix-auth-values',
  #'gub-dev-bug-8367',
  'gub-dev-allow-zero-in-phonenumber',
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
