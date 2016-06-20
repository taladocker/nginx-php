FROM ubuntu:14.04.3
MAINTAINER Hoa Nguyen <hoa.nguyenmanh@tiki.vn>

# Ensure UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8

# Setup timezone & install libraries
RUN echo "Asia/Bangkok" > /etc/timezone \
&& dpkg-reconfigure -f noninteractive tzdata \
&& apt-get install -y software-properties-common \
&& add-apt-repository -y ppa:nginx/stable && add-apt-repository -y ppa:ondrej/php5-5.6 \
&& apt-get update && apt-get install -y \
    build-essential \
    vim \
    curl \
    wget \
    dialog \
    net-tools \
    git \
    supervisor \
    nginx \
    php5-dev \
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
    php5-xdebug \
    php5-intl \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /etc/php5/cli/conf.d/20-xdebug.ini /etc/php5/fpm/conf.d/20-xdebug.ini
# Disable xdebug by default

# Install nodejs, npm, phalcon & composer
RUN curl -sL https://deb.nodesource.com/setup_6.x | sudo -E bash - \
&& apt-get install -y nodejs \
&& curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
&& ln -fs /usr/bin/nodejs /usr/local/bin/node \
&& npm config set registry http://registry.npmjs.org \
&& npm config set strict-ssl false \
&& npm install -g npm aglio bower grunt-cli gulp-cli

# Nginx & PHP & Supervisor configuration
COPY conf/nginx/vhost.conf /etc/nginx/sites-available/default
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/php56/php.ini /etc/php5/fpm/php.ini
COPY conf/php56/cli.php.ini /etc/php5/cli/php.ini
COPY conf/php56/php-fpm.conf /etc/php5/fpm/php-fpm.conf
COPY conf/php56/www.conf /etc/php5/fpm/pool.d/www.conf
COPY conf/supervisor/supervisord.conf /etc/supervisord.conf

# Forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

# Add php test file
COPY ./info.php /src/public/index.php

# Start Supervisord
COPY ./start.sh /start.sh
RUN chmod 755 /start.sh

EXPOSE 80 443

CMD ["/bin/bash", "/start.sh"]
