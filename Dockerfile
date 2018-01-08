FROM arm32v7/debian:stretch

RUN groupadd -r mysql && useradd -r -g mysql mysql

ENV MYSQL_VERSION 5.7.20

ENV GOSU_VERSION 1.7
COPY gosu /usr/local/bin/
COPY gosu.asc /usr/local/bin/
RUN set -x \
    && apt-get update && apt-get install -y --no-install-recommends ca-certificates wget gosu gnupg dirmngr && rm -rf /var/lib/apt/lists/* 
# && wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)" \
# && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture).asc" \
# RUN export GNUPGHOME="$(mktemp -d)" \
#     && gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4 \
#     && gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu \
#     # && rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc \
#     && chmod +x /usr/local/bin/gosu \
#     && gosu nobody true
#     && apt-get purge -y --auto-remove ca-certificates wget

RUN mkdir /docker-entrypoint-initdb.d

RUN apt-get update && apt-get install -y --no-install-recommends \
    # for MYSQL_RANDOM_ROOT_PASSWORD
    pwgen \
    # for mysql_ssl_rsa_setup
    openssl \
    # FATAL ERROR: please install the following Perl modules before executing /usr/local/mysql/scripts/mysql_install_db:
    # File::Basename
    # File::Copy
    # Sys::Hostname
    # Data::Dumper
    perl \
    && rm -rf /var/lib/apt/lists/*

RUN set -ex; \
    # gpg: key 5072E1F5: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
    key='A4A9406876FCBD3C456770C88C718D3B5072E1F5'; \
    export GNUPGHOME="$(mktemp -d)"; \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
    gpg --export "$key" > /etc/apt/trusted.gpg.d/mysql.gpg; \
    rm -r "$GNUPGHOME"; \
    apt-key list > /dev/null
# RUN set -x \
#     && apt-get update && apt-get install -y --no-install-recommends wget && rm -rf /var/lib/apt/lists/* 

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
    && rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld \
    && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
    # ensure that /var/run/mysqld (used for socket and lock files) is writable regardless of the UID our mysqld instance ends up having at runtime
    && chmod 777 /var/run/mysqld \
    # comment out a few problematic configuration values
    && find /etc/mysql/ -name '*.cnf' -print0 \
    | xargs -0 grep -lZE '^(bind-address|log)' \
    | xargs -rt -0 sed -Ei 's/^(bind-address|log)/#&/' \
    # don't reverse lookup hostnames, they are usually another container
    && echo '[mysqld]\nskip-host-cache\nskip-name-resolve' > /etc/mysql/conf.d/docker.cnf

RUN sed -Ei 's/^(bind-address|log)/#&/' /etc/mysql/my.cnf
RUN rm -rf ~/mysql-download
VOLUME /var/lib/mysql

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod 777 /usr/local/bin/docker-entrypoint.sh
RUN ln -s /usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat
# COPY docker-entrypoint.sh /
# RUN chmod -R 777 /docker-entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
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