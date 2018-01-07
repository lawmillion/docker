FROM alpine:latest

WORKDIR /app
VOLUME /app
COPY startup.sh /startup.sh
RUN chmod -R 777 /startup.sh

RUN apk add --no-cache mariadb mariadb-client
COPY my.cnf /etc/mysql/my.cnf

EXPOSE 3306
CMD ["/startup.sh"]