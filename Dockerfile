FROM ubuntu:14.04.3
MAINTAINER Hoa Nguyen <hoa.nguyenmanh@tiki.vn>

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Install Nginx & PHP
RUN apt-get install -y software-properties-common
RUN add-apt-repository -y ppa:nginx/stable && add-apt-repository -y ppa:ondrej/php5-5.6
RUN apt-get update && apt-get install -y \
    vim \
    curl \
    wget \
    dialog \
    net-tools \
    git \
    npm \
    supervisor \
    nginx \
    php5-fpm \
    php5-curl \
    php5-gd \
    php5-geoip \
    php5-imagick \
    php5-json \
    php5-ldap \
    php5-mcrypt \
    php5-memcache \
    php5-memcached \
    php5-mongo \
    php5-mysqlnd \
    php5-pgsql \
    php5-redis \
    php5-sqlite \
    php5-xmlrpc \
    php5-xcache \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Nginx & PHP configuration
COPY conf/vhost.conf /etc/nginx/sites-available/default

# Supervisord configuration
ADD conf/supervisord.conf /etc/supervisord.conf

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

RUN sed -i "s/;date.timezone =.*/date.timezone = UTC/" /etc/php5/fpm/php.ini && \
    sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini && \
    sed -i "s/display_errors = Off/display_errors = stderr/" /etc/php5/fpm/php.ini && \
    sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 30M/" /etc/php5/fpm/php.ini && \
    sed -i "s/;opcache.enable=0/opcache.enable=0/" /etc/php5/fpm/php.ini && \
    sed -i -e "s/;daemonize\s*=\s*yes/daemonize = no/g" /etc/php5/fpm/php-fpm.conf && \
    sed -i '/^listen = /clisten = 9000' /etc/php5/fpm/pool.d/www.conf && \
    sed -i '/^listen.allowed_clients/c;listen.allowed_clients =' /etc/php5/fpm/pool.d/www.conf && \
    sed -i '/^;catch_workers_output/ccatch_workers_output = yes' /etc/php5/fpm/pool.d/www.conf && \
    sed -i '/^;env\TEMP\ = .*/aenvDB_PORT_3306_TCP_ADDR = $DB_PORT_3306_TCP_ADDR' /etc/php5/fpm/pool.d/www.conf && \
    echo "daemon off;" >> /etc/nginx/nginx.conf

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

# Add php test file
ADD ./info.php /src/public/index.php

EXPOSE 80 443

# Start Supervisord
ADD ./start.sh /start.sh
RUN chmod 755 /start.sh

CMD ["/bin/bash", "/start.sh"]
