FROM nginx:alpine

RUN rm -rf /usr/share/nginx/html/*

COPY src/html/ /usr/share/nginx/html/

COPY src/assets/ /usr/share/nginx/html/assets/

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/health || exit 1

CMD ["nginx", "-g", "daemon off;"]