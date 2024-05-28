FROM node:14-alpine

WORKDIR /usr/src/app

RUN npm install express pg

COPY . .

EXPOSE 8000

CMD [ "node", "app.js" ]
