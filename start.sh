#!/bin/bash

# enable xdebug if ENV variable TIKI_XDEBUG_ENABLED == 1
_init_xdebug() {
  echo ":: initializing xdebug config"
  local _xdebug_enableb=${TIKI_XDEBUG_ENABLED:-0}

  if [[ $_xdebug_enableb == 1 ]] ; then
    ln -svf /etc/php/7.0/mods-available/xdebug.ini /etc/php/7.0/cli/conf.d/20-xdebug.ini
    ln -svf /etc/php/7.0/mods-available/xdebug.ini /etc/php/7.0/fpm/conf.d/20-xdebug.ini
  fi
}

exec_supervisord() {
    echo 'Start supervisord'
    /usr/bin/supervisord -n -c /etc/supervisord.conf
}

# Run helper function if passed as parameters
# Otherwise start supervisord
if [[ -n "$@" ]]; then
  $@
else
  _init_xdebug  # for corveralls.io ...
  exec_supervisord
fi
