FROM node:latest

RUN mkdir -p /app

WORKDIR /app

COPY .  /app

RUN npm install -g serve

RUN npm install

RUN npm run build

EXPOSE 5000

CMD ["serve", "-s", "build"]