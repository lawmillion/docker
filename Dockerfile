FROM alpine:latest

WORKDIR /app
VOLUME /app
COPY startup.sh /startup.sh

RUN apk add --no-cache mariadb
COPY my.cnf /etc/mysql/my.cnf

EXPOSE 3306
CMD ["/startup.sh"]