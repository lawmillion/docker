FROM php:7.1.3-alpine
MAINTAINER lawmil <452842092@qq.com>

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apk add --no-cache \
            freetype-dev \
            libjpeg-turbo-dev \
            libmcrypt-dev \
            libpng-dev \
            zlib-dev \
            git \
            unzip \
        && docker-php-ext-install opcache iconv mcrypt zip pdo pdo_mysql \
        && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
        && docker-php-ext-install gd

RUN echo 'date.timezone = Asia/Shanghai' > /usr/local/etc/php/php.ini


RUN apk add --no-cache --virtual .phpize-deps-configure $PHPIZE_DEPS \
    && pecl install redis-3.1.2 \
    && docker-php-ext-enable redis \
    && apk del .phpize-deps-configure

RUN curl -sS https://getcomposer.org/installer | php
RUN mv composer.phar /usr/local/bin/composer
RUN composer config -g repo.packagist composer https://packagist.phpcomposer.com
RUN composer global require "laravel/lumen-installer"

ENV PATH=/root/.composer/vendor/bin:$PATH
RUN export PATH
RUN echo $PATH

WORKDIR /var/www/laravel

EXPOSE 80
CMD ["php","-S","0.0.0.0:80"]