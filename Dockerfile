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
&& apt-get install -y language-pack-en-base \
&& add-apt-repository -y ppa:nginx/stable && add-apt-repository ppa:ondrej/php \
&& apt-get update && apt-get install -y \
    build-essential \
    vim \
    unzip \
    curl \
    wget \
    dialog \
    net-tools \
    git \
    supervisor \
    nginx \
    php7.0-dev \
    php7.0-fpm \
    php7.0-bcmath \
    php7.0-curl \
    php7.0-gd \
    php7.0-geoip \
    php7.0-imagick \
    php7.0-intl \
    php7.0-json \
    php7.0-ldap \
    php7.0-mbstring \
    php7.0-mcrypt \
    php7.0-memcache \
    php7.0-memcached \
    php7.0-mongo \
    php7.0-mysqlnd \
    php7.0-pgsql \
    php7.0-redis \
    php7.0-sqlite \
    php7.0-xmlrpc \
    php7.0-xdebug \
&& apt-get clean \
&& mkdir /run/php && chown www-data:www-data /run/php \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
&& rm -rf /etc/php/7.0/fpm/conf.d/20-xdebug.ini /etc/php/7.0/cli/conf.d/20-xdebug.ini
# Disable xdebug by default

# Install nodejs, npm, phalcon & composer
RUN curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash - \
&& apt-get install -y nodejs \
&& curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
&& ln -fs /usr/bin/nodejs /usr/local/bin/node \
&& npm config set registry http://registry.npmjs.org \
&& npm config set strict-ssl false \
&& npm cache clean \
&& npm install -g aglio bower grunt-cli gulp-cli

# Nginx & PHP & Supervisor configuration
COPY conf/nginx/vhost.conf /etc/nginx/sites-available/default
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/php70/php.ini /etc/php/7.0/fpm/php.ini
COPY conf/php70/cli.php.ini /etc/php/7.0/cli/php.ini
COPY conf/php70/php-fpm.conf /etc/php/7.0/fpm/php-fpm.conf
COPY conf/php70/www.conf /etc/php/7.0/fpm/pool.d/www.conf
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
