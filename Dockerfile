FROM php:7.1.3-apache

MAINTAINER lawmil <452842092@qq.com>

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get -y autoremove \
	&& apt-get clean \
	&& rm -rf /var/libs/apt/lists/*

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng12-dev \
    && docker-php-ext-install -j$(nproc) iconv mcrypt mysqli pdo pdo_mysql json \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install -j$(nproc) gd

RUN pecl install redis-3.1.1 \
    && pecl install xdebug-2.5.0 \
    && pecl install imagick-3.4.3 \
		&& pecl install zip-1.13.5 \
    && docker-php-ext-enable redis xdebug imagick zip

RUN /usr/bin/curl -sS https://getcomposer.org/installer |/usr/bin/php
RUN /bin/mv composer.phar /usr/local/bin/composer
RUN /usr/local/bin/composer config -g repo.packagist composer https://packagist.phpcomposer.com
RUN composer global require "laravel/lumen-installer"
# RUN echo '$HOME/.composer/vendor/bin:$PATH' > ~/.bashrc
ENV PATH=/root/.composer/vendor/bin:$PATH
RUN export PATH
RUN echo $PATH

RUN /usr/sbin/a2enmod rewrite

ADD 000-laravel.conf /etc/apache2/sites-available/
ADD 001-laravel-ssl.conf /etc/apache2/sites-available/
RUN /usr/sbin/a2dissite '*' && /usr/sbin/a2ensite 000-laravel 001-laravel-ssl

RUN /bin/chown www-data:www-data -R /var/www/laravel/storage /var/www/laravel/bootstrap/cache

ADD 000-default.conf /etc/apache2/sites-available/
# ADD php.ini /usr/local/etc/php/
ADD conf.d/ /usr/local/etc/php/conf.d/

RUN /bin/chown www-data:www-data -R /var/www/laravel/storage /var/www/laravel/bootstrap/cache

WORKDIR /var/www/laravel

EXPOSE 80
EXPOSE 443

CMD ["apache2-foreground"]