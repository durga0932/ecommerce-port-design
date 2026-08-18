FROM nginx:1.29-alpine

RUN rm -rf /usr/share/nginx/html/*

COPY src/html/index.html /usr/share/nginx/html/index.html
COPY src/html/authentication-login.html /usr/share/nginx/html/authentication-login.html
COPY src/html/authentication-register.html /usr/share/nginx/html/authentication-register.html
COPY src/html/icon-tabler.html /usr/share/nginx/html/icon-tabler.html
COPY src/html/sample-page.html /usr/share/nginx/html/sample-page.html
COPY src/html/ui-alerts.html /usr/share/nginx/html/ui-alerts.html
COPY src/html/ui-buttons.html /usr/share/nginx/html/ui-buttons.html
COPY src/html/ui-card.html /usr/share/nginx/html/ui-card.html
COPY src/html/ui-forms.html /usr/share/nginx/html/ui-forms.html
COPY src/html/ui-typography.html /usr/share/nginx/html/ui-typography.html

COPY src/assets /usr/share/nginx/html/assets

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]