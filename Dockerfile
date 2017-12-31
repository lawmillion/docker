FROM php:7.2.0-fpm-alpine3.7
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN apk add --no-cache \
    freetype-dev \
    libjpeg-turbo-dev \
    # libmcrypt-dev \
    libpng-dev \
    zlib-dev \
    git \
    zip \
    unzip \
    # supervisor \
    nginx \
    && docker-php-ext-install opcache iconv pdo pdo_mysql bcmath \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd
RUN echo -e 'date.timezone = Asia/Shanghai;\nmemory_limit = 256M;' > /usr/local/etc/php/php.ini
RUN curl -sS https://getcomposer.org/installer | php && \
    mv composer.phar /usr/local/bin/composer && \
    composer config -g repo.packagist composer https://packagist.phpcomposer.com
COPY nginx.conf /etc/nginx/nginx.conf
RUN sed -i 's/user = www-data/user = root/g' /usr/local/etc/php-fpm.d/www.conf\
    && sed -i 's/group = www-data/group = root/g' /usr/local/etc/php-fpm.d/www.conf\
    && mkdir /etc/supervisor.d/\
    && mkdir /run/nginx/\
    && echo -e '#!/bin/sh\n'\
    'ln -sf /dev/stdout /var/log/nginx/access.log\n'\
    'ln -sf /dev/stderr /var/log/nginx/error.log\n'\
    'nginx -g "daemon off;"'\
    # 'exec supervisord -n -c /etc/supervisord.conf'
    > /usr/sbin/x_init\
    && chmod a+x /usr/sbin/x_init
WORKDIR /var/www/laravel/
EXPOSE 80
CMD ["x_init"]