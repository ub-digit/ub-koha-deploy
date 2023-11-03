## CAPISTRANO ##

# config valid only for Capistrano 3.1
#lock '3.2.1'

set :application, 'koha'
#set :repo_url, 'https://github.com/ub-digit/Koha.git'
set :repo_url, 'git@github.com:ub-digit/Koha-build.git'

set :repo_remotes, {
  'origin' => 'git@github.com:ub-digit/Koha.git',
  'koha-build' => 'git@github.com:ub-digit/Koha-build.git'
}

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call
set :branch, 'release-2023.09-20231026.1138'

set :koha_deploy_branches_prefix, ''
set :koha_deploy_release_branch_prefix, 'release-2023.09-'
set :koha_deploy_release_branch_start_point, 'koha-build-master'

set :koha_deploy_rebase_branches, [
  'gub-bug-18129-staged-imports-user-filter',
  'gub-bug-18138-marc-modification-template-on-biblio-save',
  'gub-bug-29440-25539-29597-29654-bulkmarcimport', # Sammanslagen branch av bulkmarc-relaterade brancher, 29440 applyas först, sedan de andra.
  'gub-dev-remove-lost-item-refund-msg',
  'gub-dev-koha-svc',
  'gub-dev-simplified-messaging',
  'gub-overdue-messaging',
  'gub-dev-acquisitions-uncertain-price-on-importing',
  'gub-dev-acquisitions-recalculate-price',
  'gub-dev-css-for-slip-prints',  # Bör flyttas till statisk fil vid tillfälle
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
  'gub-dev-show-852-in-biblio',
  'gub-dev-fromdate-in-fines',
  #'gub-dev-fix-unitprice-decimal', # Ändrats mycket, omgjort till modal. Kolla om vi kan köra utan denna
  'gub-dev-incomplete-barcode',
  #'gub-bug-23548-aq-field-required', # Med i master
  'gub-dev-hides-dateofbirth-and-library-filters-from-patron-search',
  'gub-dev-sort-collation-sv',
  'gub-dev-hide-checkout-history-button-in-biblio-view',
  'gub-dev-hides-circulation-history-and-holds-history-in-patron-post',
  #'gub-dev-hides-last-returned-by-and-last-borrower-and-previous-borrower-in-item-view', # Detta är flyttat till gub-dev-hide-fields-in-item-view
  'gub-dev-hide-fields-in-item-view',
  'gub-dev-hides-pay-all-fines-button-in-patron-checkout-view',
  'gub-dev-hides-show-all-transactions-filter-button-in-borrower-accounting-view',
  'gub-dev-adaptation-of-warning-message-when-deleting-bilio-if-biblio-has-an-order-post',
  'gub-dev-hide-search-sort-options',
  'gub-dev-limit-visible-patron-notices',
  'gub-dev-acqusition-form-hide-unused-items',
  'gub-dev-mandatory-account-selection-in-acqusition',
  'gub-bug-24720-special-chars-normalize-sort-fields',
  'auto-renew-borrower-account-cron',
  'gub-dev-intra-hide-revert-waiting-btn',
  'gub-dev-hide-editable-date-holds-table',
  'gub-dev-revert-total-calculation-from-23522',
  'gub-dev-cleaning-scripts',
  'gub-dev-online-payments',
  'gub-dev-koha-1527-alphabetical-sorting-of-accounts',
  'gub-dev-koha-1545-set-permanent-location',
  'gub-dev-remove-tabs-from-make-payment',
  'gub-bug-27859-marc-export-search-result',
  'gub-dev-set-default-biblio-in-orders-when-missing',
  'gub-dev-lost-status-update-for-paid-issues',
  'gub-dev-force-default-replacementcost',
  'gub-dev-allow-zero-vendor-id',
  'koha-1662-hide-existing-holds-priority-dropdown',
  'gub-dev-remove-graphics-magick-dep',
  'gub-update-permissions',
  'gub-dev-environment-assets',
  'bug-30255-batchmod-optional-list-step',
  #'gub-dev-anonymize-db', # Gör inte rätt, ska arbetas om
  'gub-dev-sip-password-from-attribute',
  'gub-dev-basket-id-as-column',
  'gub-dev-offpc-extgen-pw',
  #'gub-bug-xxxx-circulation-optimizations', # Uppdelad i följande tre brancher
  #'gub-bug-31735-32476-circulation-optimizations', # 31735 med i master 32496 (felaktigt angiven i branchnamnet) hämtas i följande branch (numera med i master).
  'gub-bug-32496-reduce-unnecessary-unblessings-of-objects-in-circulation',
  'gub-bug-32476-add-patron-caching',
  #'gub-bug-32478-change-yaml-parser', # Med i master
  #'gub-bug-31734-add-plugin-hooks', # Uppdelad i fyra, varad en (31897) inte är med i master
  'gub-bug-31897-new-hook-when-indexing-with-elasticsearch',
  'gub-dev-disable-stats',
  'gub-bug-31846-serials-search-max-limit',
  'gub-bug-31856-serials-search-performance',
  #'gub-bug-31663-display-item-transfers-correctly', # Med i master
  #'gub-bug-31871-fix-date-due-on-moredetail', # Med i master
  'gub-dev-make-extended-attributes-hidable-and-not-editable',
  'gub-dev-hook-for-adding-template-paths',
  'gub-bug-xxxxx-add-hook-circulation-return-no-issue',
  #'gub-bug-31646-focus-input-by-default-when-clicking-on-a-dropdown-field-in-the-cataloguing-editor', # Med i master
  'gub-dev-remove-welcome-email-option',
  #'gub-bug-32060-faster-columns_to_string', # Med i master
  'gub-bug-32092-circulation-rules-cache',
  'gub-dev-disable-online-payments-syspref',
  'gub-dev-cache-itemtypes-find',
  'gub-dev-cache-libraries-find',
  'gub-dev-cache-item-pickup-locations',
  'gub-dev-manual-bundle-count',
  'gub-dev-acqui-home-speedup',
  #'gub-bug-31818-show-keyboard-shortcuts-in-advanced-cataloguing-editor', # Med i master
  'gub-dev-fix-item-details-view',
  #'gub-bug-31782-fix-broken-patron-autocomplete', # Denna hämtades från Bugzilla men löste inte vårt problem.
  #'gub-bug-32975-fix-package-json-definition-error', # Med i master
  #'gub-bug-32978-fix-npm-install-error', # Med i master
  'gub-dev-add-compiled-assets', # Se instruktioner https://github.com/ub-digit/koha-assets-build
  'gub-dev-always-show-circ-settings',
  #'gub-dev-fix-compare-bug', # Denna bör vara åtgärdad i master, testa
  'gub-dev-acqusition-form-set-quantity-maxlength',
  'gub-dev-limit-edifact-list',
  'gub-dev-anonymize-pickup-code',
  'gub-dev-show-correct-manage-staged-records-link',
  'gub-dev-hide-empty-subfield-rows',
  'gub-dev-fix-dateenrolled-bug-on-duplicate-patron',
  #'gub-dev-show-only-3-latest-checkouts', # Åtgärdad i master
  'gub-dev-fix-basket-created-by-search',
  #'gub-bug-33014-add-link-to-serial-advanced-search', # Med i master
  'gub-dev-dont-show-change-messaging-preferences-confirm',
  'gub-dev-sync-message-preferences-with-syspref',
  #'gub-bug-33721-fix-display-of-shipping-cost-fund', # Med i master
  'gub-dev-log-patron-attributes',
  'gub-bug-xxxxx-ignore-empty-barcode-on-checkout',
  'gub-dev-set-always-sms-provider',
  'gub-bug-xxxxx-fix-column-count-for-transaction-filters',
  'gub-dev-retry-unfound-backgroundjobs',
  'gub-dev-subscription-holds',
  'gub-bug-35004-fix-error-about-no-quantity-set',
  'gub-dev-hide-shipping-found-dropdown',
  'gub-bug-35133-accessors-super-fix',
  'gub-dev-fix-reldebarments-href-error',
  'gub-dev-library-properties-template-plugin',
  'gub-dev-show-patron-flags-and-edit-links',
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
  misc/translator/po/sv-SE-installer-UNIMARC.po
  misc/translator/po/sv-SE-installer.po
  misc/translator/po/sv-SE-marc-MARC21.po
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
