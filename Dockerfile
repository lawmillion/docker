FROM node:alpine
MAINTAINER lawmil <452842092@qq.com>
WORKDIR /app
RUN npm install -g cnpm --registry=https://registry.npm.taobao.org
EXPOSE 80
CMD ["npm", "run", "dev"]