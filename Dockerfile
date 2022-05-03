FROM node:14

WORKDIR /opt/work

COPY . .

RUN npm install && npm run build

FROM nginx:1.20

COPY --from=0 /opt/work/dist /usr/share/nginx/html