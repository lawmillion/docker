FROM eboraas/laravel:latest

ENV TZ=Asia/Shanghai

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN /usr/local/bin/composer config -g repo.packagist composer https://packagist.phpcomposer.com

RUN composer global require "laravel/lumen-installer"

# RUN echo '$HOME/.composer/vendor/bin:$PATH' > ~/.bashrc

ENV PATH=/root/.composer/vendor/bin:$PATH

RUN export PATH

RUN echo $PATH
