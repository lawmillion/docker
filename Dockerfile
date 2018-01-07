FROM arm32v7/debian:stretch-slim

RUN groupadd -r mysql && useradd -r -g mysql mysql

ENV MYSQL_VERSION 5.7.20

RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends wget && rm -rf /var/lib/apt/lists/* 

RUN mkdir ~/mysql-download/ && cd ~/mysql-download/\
    && wget http://ftp.debian.org/debian/pool/main/m/mysql-5.7/libmysqlclient-dev_$MYSQL_VERSION-1_armhf.deb\
    && wget http://ftp.debian.org/debian/pool/main/m/mysql-5.7/libmysqlclient20_$MYSQL_VERSION-1_armhf.deb\
    && wget http://ftp.debian.org/debian/pool/main/m/mysql-5.7/libmysqld-dev_$MYSQL_VERSION-1_armhf.deb\
    && wget http://ftp.debian.org/debian/pool/main/m/mysql-5.7/mysql-client-5.7_$MYSQL_VERSION-1_armhf.deb\
    && wget http://ftp.debian.org/debian/pool/main/m/mysql-5.7/mysql-client-core-5.7_$MYSQL_VERSION-1_armhf.deb\
    && wget http://ftp.debian.org/debian/pool/main/m/mysql-5.7/mysql-server-5.7_$MYSQL_VERSION-1_armhf.deb\
    && wget http://ftp.debian.org/debian/pool/main/m/mysql-5.7/mysql-server-core-5.7_$MYSQL_VERSION-1_armhf.deb\
    && wget http://ftp.debian.org/debian/pool/main/m/mecab/libmecab2_0.996-3.1_armhf.deb\
    && wget http://ftp.debian.org/debian/pool/main/m/mysql-defaults/mysql-common_5.8+1.0.3_all.deb\
    && wget http://ftp.debian.org/debian/pool/main/l/lz4/liblz4-1_0.0~r131-2+b1_armhf.deb\
    && wget http://ftp.debian.org/debian/pool/main/libe/libevent/libevent-2.1-6_2.1.8-stable-4_armhf.deb\
    && wget http://ftp.debian.org/debian/pool/main/libe/libevent/libevent-core-2.1-6_2.1.8-stable-4_armhf.deb

RUN apt-get update\
    && apt-get install -y libedit2 libwrap0 libaio1 libaio-dev libhtml-template-perl psmisc gcc-6 g++-6\
    && rm -rf /var/lib/apt/lists/* 

RUN cd ~/mysql-download/\
    && dpkg -i libevent-2.1-6_2.1.8-stable-4_armhf.deb\
    && dpkg -i libevent-core-2.1-6_2.1.8-stable-4_armhf.deb\
    && dpkg -i libmecab2_0.996-3.1_armhf.deb\
    && dpkg -i liblz4-1_0.0~r131-2+b1_armhf.deb\
    && dpkg -i mysql-common_5.8+1.0.3_all.deb\
    && dpkg -i mysql-client-core-5.7_${MYSQL_VERSION}-1_armhf.deb\
    && dpkg -i mysql-client-5.7_${MYSQL_VERSION}-1_armhf.deb\
    && dpkg -i mysql-server-core-5.7_${MYSQL_VERSION}-1_armhf.deb\
    && dpkg -i mysql-server-5.7_${MYSQL_VERSION}-1_armhf.deb
RUN { \
    echo mysql-server mysql-server/data-dir select ''; \
    echo mysql-server mysql-server/root-pass password ''; \
    echo mysql-server mysql-server/re-root-pass password ''; \
    echo mysql-server mysql-server/remove-test-db select false; \
    } | debconf-set-selections \
    && rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql && chown -R mysql:mysql /var/lib/mysql

RUN sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf
RUN rm -rf ~/mysql-download
VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /
RUN chmod -R 777 /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 3306
CMD ["mysqld"]
# WORKDIR /app
# VOLUME /app
# COPY startup.sh /startup.sh
# RUN chmod -R 777 /startup.sh

# RUN apk add --no-cache mysql mysql-client
# COPY my.cnf /etc/mysql/my.cnf

# EXPOSE 3306
# CMD ["/startup.sh"]