# FROM arm32v7/debian:jessie-slim

# # add our user and group first to make sure their IDs get assigned consistently, regardless of whatever dependencies get added
# RUN groupadd -r mysql && useradd -r -g mysql mysql
# # RUN ping -c 1 github.com
# # RUN ping -c 1 ha.pool.sks-keyservers.net
# # RUN ip route
# # COPY gosu-amd64 /usr/local/bin/gosu
# # COPY gosu-amd64.asc /usr/local/bin/gosu.asc
# ENV GOSU_VERSION 1.10
# RUN set -ex; \
#     \
#     fetchDeps='ca-certificates'; \
#     apt-get update; \
#     apt-get install -y --no-install-recommends $fetchDeps; \
#     rm -rf /var/lib/apt/lists/*; \
#     \
#     dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
#     wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
#     wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
#     export GNUPGHOME="$(mktemp -d)"; \
#     gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
#     gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
#     rm -r "$GNUPGHOME" /usr/local/bin/gosu.asc; \
#     chmod +x /usr/local/bin/gosu; \
#     gosu nobody true; \
#     \
#     apt-get purge -y --auto-remove $fetchDeps

# RUN mkdir /docker-entrypoint-initdb.d

# RUN apt-get update && apt-get install -y --no-install-recommends \
#     # for MYSQL_RANDOM_ROOT_PASSWORD
#     pwgen \
#     # for mysql_ssl_rsa_setup
#     openssl \
#     # FATAL ERROR: please install the following Perl modules before executing /usr/local/mysql/scripts/mysql_install_db:
#     # File::Basename
#     # File::Copy
#     # Sys::Hostname
#     # Data::Dumper
#     perl \
#     && rm -rf /var/lib/apt/lists/*

# RUN set -ex; \
#     # gpg: key 5072E1F5: public key "MySQL Release Engineering <mysql-build@oss.oracle.com>" imported
#     key='A4A9406876FCBD3C456770C88C718D3B5072E1F5'; \
#     export GNUPGHOME="$(mktemp -d)"; \
#     gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; \
#     gpg --export "$key" > /etc/apt/trusted.gpg.d/mysql.gpg; \
#     rm -r "$GNUPGHOME"; \
#     apt-key list > /dev/null

# ENV MYSQL_MAJOR 5.7
# ENV MYSQL_VERSION 5.7.20-1

# RUN echo "deb http://repo.mysql.com/apt/debian/ jessie mysql-${MYSQL_MAJOR}" > /etc/apt/sources.list.d/mysql.list

# # the "/var/lib/mysql" stuff here is because the mysql-server postinst doesn't have an explicit way to disable the mysql_install_db codepath besides having a database already "configured" (ie, stuff in /var/lib/mysql/mysql)
# # also, we set debconf keys to make APT a little quieter
# RUN { \
#     echo mysql-community-server mysql-community-server/data-dir select ''; \
#     echo mysql-community-server mysql-community-server/root-pass password ''; \
#     echo mysql-community-server mysql-community-server/re-root-pass password ''; \
#     echo mysql-community-server mysql-community-server/remove-test-db select false; \
#     } | debconf-set-selections \
#     && apt-get update && apt-get install -y mysql-server="${MYSQL_VERSION}" && rm -rf /var/lib/apt/lists/* \
#     && rm -rf /var/lib/mysql && mkdir -p /var/lib/mysql /var/run/mysqld \
#     && chown -R mysql:mysql /var/lib/mysql /var/run/mysqld \
#     # ensure that /var/run/mysqld (used for socket and lock files) is writable regardless of the UID our mysqld instance ends up having at runtime
#     && chmod 777 /var/run/mysqld \
#     # comment out a few problematic configuration values
#     && find /etc/mysql/ -name '*.cnf' -print0 \
#     | xargs -0 grep -lZE '^(bind-address|log)' \
#     | xargs -rt -0 sed -Ei 's/^(bind-address|log)/#&/' \
#     # don't reverse lookup hostnames, they are usually another container
#     && echo '[mysqld]\nskip-host-cache\nskip-name-resolve' > /etc/mysql/conf.d/docker.cnf

# VOLUME /var/lib/mysql

# COPY docker-entrypoint.sh /usr/local/bin/
# RUN ln -s usr/local/bin/docker-entrypoint.sh /entrypoint.sh # backwards compat
# ENTRYPOINT ["docker-entrypoint.sh"]

# EXPOSE 3306
# CMD ["mysqld"]
# # CMD ["/bin/sh","-c","while true;do echo hello docker;sleep 1;done"]
FROM alpine:latest
RUN addgroup mysql && adduser -S -G mysql mysql
RUN mkdir /docker-entrypoint-initdb.d
RUN apk add --no-cache mariadb-server \
    # { \
    #     echo "mariadb-server-$MARIADB_MAJOR" mysql-server/root_password password 'unused'; \
    #     echo "mariadb-server-$MARIADB_MAJOR" mysql-server/root_password_again password 'unused'; \
    #     } | debconf-set-selections \
    && sed -ri 's/^user\s/#&/' /etc/mysql/my.cnf /etc/mysql/conf.d/* \
    # purge and re-create /var/lib/mysql with appropriate ownership
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
VOLUME /var/lib/mysql
COPY docker-entrypoint.sh /usr/local/bin/
RUN ln -s usr/local/bin/docker-entrypoint.sh / # backwards compat
ENTRYPOINT ["docker-entrypoint.sh"]
EXPOSE 3306
CMD [ "mysqld",'--user=mysql']