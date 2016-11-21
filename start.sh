#!/bin/bash

# enable xdebug if ENV variable TIKI_XDEBUG_ENABLED == 1
_init_xdebug() {
  local _xdebug_enableb=${TIKI_XDEBUG_ENABLED:-0}
  echo ":: initializing xdebug config (_xdebug_enableb=${_xdebug_enableb})"

  if [[ $_xdebug_enableb == 1 ]] ; then
    ln -svf /etc/php/7.0/mods-available/xdebug.ini /etc/php/7.0/cli/conf.d/20-xdebug.ini
    ln -svf /etc/php/7.0/mods-available/xdebug.ini /etc/php/7.0/fpm/conf.d/20-xdebug.ini
  fi
}

# if ENV variable TK_IS_WORKER == 1
# -> only start worker process (dont start nginx, php-fpm)
_init_worker() {
  local _is_worker=${TK_IS_WORKER:-0}
  echo ":: initializing worker config (_is_worker=${_is_worker})"

  if [[ $_is_worker == 1 ]] ; then
    sed -i 's#autostart=.*#autostart=false#g' /etc/supervisord.conf  # dont start nginx, php-fpm
    # include worker config
    [[ -d /etc/supervisor.d ]] || mkdir -v /etc/supervisor.d
    grep -q include /etc/supervisord.conf \
    || echo -e "[include]\nfiles = /etc/supervisor.d/*.conf\n" >> /etc/supervisord.conf
  fi
}

# start newrelic if ENV variable TK_NEWRELIC_ENABLED == 1
# newrelic config:
#   TK_NEWRELIC_LICENCE=foobar
#   TK_NEWRELIC_APPNAME=foobar
_init_newrelic() {
  local _newrelic_enableb=${TK_NEWRELIC_ENABLED:-0}
  echo ":: initializing newrelic config (_newrelic_enableb=${_newrelic_enableb})"

  if [[ $_newrelic_enableb == 1 ]] ; then
    local _f_conf="/etc/php/7.0/mods-available/newrelic.ini"
    local _license=${TK_NEWRELIC_LICENCE:-}
    local _app_name=${TK_NEWRELIC_APPNAME:-tk-nginx-php}

    sed -i "s#newrelic.license = .*#newrelic.license = \"${_license}\"#g" $_f_conf
    sed -i "s#newrelic.appname = .*#newrelic.appname = \"${_app_name}\"#g" $_f_conf

    ln -svf "$_f_conf" /etc/php/7.0/cli/conf.d/20-newrelic.ini
    ln -svf "$_f_conf" /etc/php/7.0/fpm/conf.d/20-newrelic.ini
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
  _init_worker
  _init_newrelic
  exec_supervisord
fi
