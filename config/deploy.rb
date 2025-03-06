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
set :branch, 'release-2025.01-20250306.1113'
###set :branch, 'release-2024.02-20250214.1313' # RELEASE för lösenordsbytes-grejerna

set :koha_deploy_branches_prefix, ''
set :koha_deploy_release_branch_prefix, 'release-2025.01-'
set :koha_deploy_release_branch_start_point, 'koha-build-master'

set :koha_deploy_rebase_branches, [
  'gub-bug-18129-staged-imports-user-filter',
  #'gub-bug-18138-marc-modification-template-on-biblio-save', # Används troligen inte, tas bort tills vidare
  #'gub-bug-29440-25539-29597-29654-bulkmarcimport', # 29440 och 25539 med i master, de andra läggs på separat
  'gub-bug-29597-add-tomarcplugin-option-to-bulkmarcimport',
  'gub-bug-29654-add-option-to-bulkmarimport-for-matching-on-original-id',
  'gub-dev-remove-lost-item-refund-msg',
  'gub-dev-koha-svc',
  'gub-dev-simplified-messaging',
  #'gub-overdue-messaging', # Ersatt med nedanstående
  'gub-bug-30515-move-overdue-transports-to-patron-messaging-preferences',
  'gub-dev-acquisitions-uncertain-price-on-importing',
  'gub-dev-acquisitions-recalculate-price',
  'gub-dev-css-for-slip-prints',  # Bör flyttas till statisk fil vid tillfälle
  'gub-dev-set-focus-on-confirm-hold-and-transfer-button',
  'gub-dev-advanced-search-customizations',
  'gub-dev-auto-add-001',
  #'gub-dev-callnumber-095-fallback', # Visningen ändrad, avvaktar med denna
  #'gub-dev-gub-format-facet', # Kan göras via gränssnittet istället
  'gub-dev-circulation-reports',
  'gub-dev-extended-inhouse-loans',
  'gub-dev-edifact-cron',
  #'gub-bug-20551-export-records-deleted', # Ingår i gub-bug-23009-deleted-marc-conditions
  'gub-bug-23009-deleted-marc-conditions', # Denna har ett beroende till 20551 vilken är med i denna branch
  'gub-dev-cache-subscription-frequencies', # Den generella cache-lösningen täcker troligen inte denna
  'gub-change-sort-order-and-paging-for-table-subscription-numberpatterns',
  'gub-dev-show-852-in-biblio',
  'gub-dev-fromdate-in-fines',
  'gub-dev-incomplete-barcode',
  'gub-dev-hides-dateofbirth-and-library-filters-from-patron-search',
  'gub-dev-sort-collation-sv',
  'gub-dev-hide-checkout-history-button-in-biblio-view',
  'gub-dev-hides-circulation-history-and-holds-history-in-patron-post',
  'gub-dev-hide-fields-in-item-view',
  'gub-dev-hides-pay-all-fines-button-in-patron-checkout-view',
  'gub-dev-hides-show-all-transactions-filter-button-in-borrower-accounting-view',
  'gub-dev-adaptation-of-warning-message-when-deleting-bilio-if-biblio-has-an-order-post',
  'gub-dev-hide-search-sort-options',
  'gub-dev-limit-visible-patron-notices',
  'gub-dev-acqusition-form-hide-unused-items',
  #'gub-dev-mandatory-account-selection-in-acqusition', # Filen acqui/edi_ean.pl borttagen, men denna patch behövs troligen inte längre
  'gub-bug-24720-special-chars-normalize-sort-fields',
  'auto-renew-borrower-account-cron',
  'gub-dev-intra-hide-revert-waiting-btn',
  'gub-dev-hide-editable-date-holds-table',
  'gub-dev-revert-total-calculation-from-23522', # Kolla ifall denna fortfarande behövs (se t.ex. 25750)
  'gub-dev-cleaning-scripts',
  'gub-dev-online-payments',
  'gub-dev-koha-1527-alphabetical-sorting-of-accounts', # acqui/edi_ean.pl borttagen, patchen flyttad
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
  'gub-dev-sip-password-from-attribute',
  'gub-dev-basket-id-as-column',
  'gub-dev-offpc-extgen-pw',
  'gub-bug-32476-add-patron-caching',
  'gub-bug-31897-new-hook-when-indexing-with-elasticsearch', # Finns likande lösning i 36433 med vi använder vår patch
  'gub-dev-disable-stats',
  'gub-bug-36350-add-caching-at-koha-objects-level', # Ersätter ett antal brancher
  'gub-bug-31856-serials-search-performance',
  #'gub-dev-make-extended-attributes-hidable-and-not-editable', # Ersatt med nedanstående
  'gub-dev-extended-attributes-visibility-properties',
  #'gub-bug-xxxxx-add-hook-circulation-return-no-issue', # Finns i bugzilla (36303) och patchen är ersatt med gub-bug-36303-add-hook-circulation-return-no-issue
  'gub-bug-36303-add-hook-circulation-return-no-issue',
  'gub-dev-remove-welcome-email-option',
  'gub-bug-32092-circulation-rules-cache',
  'gub-dev-disable-online-payments-syspref',
  #'gub-dev-cache-itemtypes-find', # Löses via 36350
  #'gub-dev-cache-libraries-find', # Löses via 36350
  #'gub-dev-cache-item-pickup-locations', # Löses via 36350
  'gub-dev-manual-bundle-count',
  #'gub-dev-acqui-home-speedup', # Löses via 36350
  'gub-dev-fix-item-details-view', # Kolla ifall denna bugg är åtgärdad, alt. ifall denna kan levereras
  'gub-dev-add-compiled-assets', # Se instruktioner https://github.com/ub-digit/koha-assets-build
  'gub-dev-always-show-circ-settings',
  'gub-dev-acqusition-form-set-quantity-maxlength',
  'gub-dev-anonymize-pickup-code',
  'gub-dev-hide-empty-subfield-rows', # Borde ev levereras
  'gub-dev-fix-dateenrolled-bug-on-duplicate-patron', # Borde ev levereras
  #'gub-dev-fix-basket-created-by-search', # med i master
  'gub-dev-dont-show-change-messaging-preferences-confirm',
  'gub-dev-sync-message-preferences-with-syspref',
  #'gub-dev-log-patron-attributes', # Ersatt med nedanstående
  'gub-bug-26744-log-patron-attributes',
  #'gub-bug-35149-ignore-empty-barcode-on-checkout', # Med i master
  'gub-dev-set-always-sms-provider',
  #'gub-dev-retry-unfound-backgroundjobs', # Motsvarande lösning verkar finnas i master (35819)
  'gub-dev-subscription-holds',
  'gub-dev-hide-shipping-found-dropdown',
  'gub-dev-library-properties-template-plugin',
  #'gub-dev-show-patron-flags-and-edit-links', # Med i master (36440)
  'gub-dev-reserve-template-plugin',
  'gub-dev-do-not-show-patron-data-at-check-in',
  'gub-dev-add-edi-message-button-to-basket-view', # Kanske kan levereras
  #'gub-dev-fix-edifact-list-typo', # Med i master
  'gub-dev-myloans-alert-from-koha',
  'gub-dev-publisher-number-delimiter',
  'gub-bug-36022-default-country-code',
  #'gub-dev-fix-checkout-list-error', # Fixad i master (bugg introducerad i 35506, löst i 36581)
  'gub-dev-add-search-field-aliases',
  'gub-dev-edifact-status-case-insensitive-error-fix',
  'gub-dev-stage-marc-auto-select-profile',
  'gub-dev-show-special-notices',
  'gub-dev-private-reports',
  'gub-dev-disable-host-items-on-detail-page',
  'gub-bug-30279-patron-view-log',
  #'gub-dev-fix-wrong-csrf-token-issue-on-oidc-login', # Dessa patchar (36102 och 36149) är med i master
  'gub-dev-always-exclude-patrons-view-entries-from-log-viewer',
  'gub-dev-set-limit-for-number-of-rows-in-action-logs',
  'gub-dev-change-order-default-quantity',
  'gub-dev-always-allow-table-settings',
  'gub-bug-39229-extend-patron-quicksearch', # Denna har en extra commit med lokala förändringar, detta behöver hanteras vid rebase

  # Security patches
  #'gub-sec-37247-on-subscriptions-operation-allowed-without-authentication', # med i master
  #'gub-sec-36818-rce-in-upload-cover-image', # med i master
  #'gub-sec-37323-rce-in-picture-upload', # med i master
  #'gub-sec-37464-rce-in-barcode-function-leads-to-reverse-shell', # med i master

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
