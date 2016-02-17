# Start supervisord and services
echo 'Start supervisord'
/usr/bin/supervisord -n -c /etc/supervisord.conf
