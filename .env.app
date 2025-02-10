APP_NAME: $PROJECT_NAME
APP_ENV: local
APP_DEBUG: true
APP_TIMEZONE: $APP_TIMEZONE
APP_URL: $PROJECT_BASE_URL

# Database
DB_HOST: $DB_HOST
DB_DATABASE: $DB_DATABASE
DB_USERNAME: $DB_USERNAME
DB_PASSWORD: $DB_PASSWORD

# PHP
# By default xdebug extension also disabled.
PHP_EXTENSIONS_DISABLE: xhprof,spx
PHP_MAIL_MIXED_LF_AND_CRLF: On
PHP_FPM_USER: wodby
PHP_FPM_GROUP: wodby

## Read instructions at https://wodby.com/docs/stacks/php/local/#xdebug
#      PHP_XDEBUG_MODE: debug
#      PHP_XDEBUG_MODE: profile
#      PHP_XDEBUG_USE_COMPRESSION: false
#      PHP_IDE_CONFIG: serverName=my-ide
#      PHP_XDEBUG_IDEKEY: "my-ide"
