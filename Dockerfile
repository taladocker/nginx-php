FROM ubuntu:16.04
MAINTAINER Hoa Nguyen <hoa.nguyenmanh@tiki.vn>

# ENV
ENV DEBIAN_FRONTEND noninteractive
ENV LANG       en_US.UTF-8
ENV LC_ALL     en_US.UTF-8
ENV TZ         Asia/Saigon

# timezone and locale
RUN apt-get update \
    && apt-get install -y software-properties-common \
        language-pack-en-base \
        apt-utils tzdata locales \
    && locale-gen en_US.UTF-8 \
    && echo $TZ > /etc/timezone \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && apt-get autoclean \
    && rm -vf /var/lib/apt/lists/*.* /tmp/* /var/tmp/*

# php
RUN add-apt-repository -y ppa:nginx/stable \
    && add-apt-repository ppa:ondrej/php \
    && apt-get update \
    && apt-get install -y build-essential \
    vim \
    unzip \
    curl \
    wget \
    dialog \
    net-tools \
    git \
    supervisor \
    python-pip \
    nginx \
    php7.1-common \
    php7.1-dev \
    php7.1-fpm \
    php7.1-bcmath \
    php7.1-curl \
    php7.1-gd \
    php7.1-geoip \
    php7.1-imagick \
    php7.1-intl \
    php7.1-json \
    php7.1-ldap \
    php7.1-mbstring \
    php7.1-mcrypt \
    php7.1-memcache \
    php7.1-memcached \
    php7.1-mongo \
    php7.1-mysqlnd \
    php7.1-pgsql \
    php7.1-redis \
    php7.1-sqlite \
    php7.1-xml \
    php7.1-xmlrpc \
    php7.1-zip \
    php7.1-xdebug \
&& echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' > /etc/apt/sources.list.d/newrelic.list \
&& curl -sSL https://download.newrelic.com/548C16BF.gpg | apt-key add - \
&& apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y newrelic-php5 \
&& pip install superlance slacker \
&& mkdir /run/php && chown www-data:www-data /run/php \
&& rm -vf /etc/php/7.1/fpm/conf.d/20-xdebug.ini /etc/php/7.1/cli/conf.d/20-xdebug.ini \
&& rm -vf /etc/php/7.1/fpm/conf.d/20-newrelic.ini /etc/php/7.1/cli/conf.d/20-newrelic.ini \
&& apt-get autoclean \
&& rm -vf /var/lib/apt/lists/*.* /tmp/* /var/tmp/*

# Disable xdebug, newrelic by default

# Install php-rdkafka
RUN curl -sSL https://github.com/edenhill/librdkafka/archive/v0.9.3.tar.gz | tar xz \
    && cd librdkafka-0.9.3 \
    && ./configure && make && make install \
    && cd .. && rm -rf librdkafka-0.9.3

RUN curl -sSL https://github.com/arnaud-lb/php-rdkafka/archive/3.0.1.tar.gz | tar xz \
    && cd php-rdkafka-3.0.1 \
    && phpize && ./configure && make all && make install \
    && echo "extension=rdkafka.so" > /etc/php/7.1/mods-available/rdkafka.ini \
    && phpenmod rdkafka \
    && cd .. && rm -rf php-rdkafka-3.0.1

# Install nodejs, npm, phalcon & composer
RUN curl -sL  https://deb.nodesource.com/setup_10.x | bash -\
&& apt-get install -y nodejs \
&& curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer \
#&& ln -fs /usr/bin/nodejs /usr/local/bin/node \
#&& npm config set registry http://registry.npmjs.org \
#&& npm config set strict-ssl false \
#&& npm cache clean \
#&& npm install -g aglio bower grunt-cli gulp-cli \
&& apt-get autoclean \
&& rm -vf /var/lib/apt/lists/*.*

# Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg |  apt-key add - \
&& echo "deb https://dl.yarnpkg.com/debian/ stable main" |  tee /etc/apt/sources.list.d/yarn.list \
&&  apt-get update &&  apt-get install yarn -y

# Install superslacker (supervisord notify to slack)
RUN curl -sSL https://raw.githubusercontent.com/luk4hn/superslacker/state_change_msg/superslacker/superslacker.py > /usr/local/bin/superslacker \
    && chmod 755 /usr/local/bin/superslacker

# Nginx & PHP & Supervisor configuration
COPY conf/nginx/vhost.conf /etc/nginx/sites-available/default
COPY conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/php71/php.ini /etc/php/7.1/fpm/php.ini
COPY conf/php71/cli.php.ini /etc/php/7.1/cli/php.ini
COPY conf/php71/php-fpm.conf /etc/php/7.1/fpm/php-fpm.conf
COPY conf/php71/www.conf /etc/php/7.1/fpm/pool.d/www.conf
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
