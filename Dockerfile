FROM arm64v8/alpine:3.7
RUN apk add --no-cache mysql mysql-client
ENTRYPOINT ["mysql"]