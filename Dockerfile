FROM nginx:alpine

RUN rm -rf /usr/share/nginx/html/*

COPY src/assets /usr/share/nginx/html/assets
COPY src/html /usr/share/nginx/html

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]