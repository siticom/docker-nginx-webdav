FROM alpine:3.9 as builder

RUN apk add --no-cache alpine-sdk libxml2-dev libxslt-dev pcre-dev perl-dev

ARG nginx_version="1.16.0"
ARG nginx_dav_ext_module_version="3.0.0"
ARG nginx_headers_more_module_version="0.33"

ADD http://nginx.org/download/nginx-${nginx_version}.tar.gz /usr/local/src/nginx.tar.gz
ADD https://github.com/arut/nginx-dav-ext-module/archive/v${nginx_dav_ext_module_version}.zip /usr/local/src/nginx-dav-ext-module.zip
ADD https://github.com/openresty/headers-more-nginx-module/archive/v${nginx_headers_more_module_version}.zip /usr/local/src/headers-more-nginx-module.zip

RUN cd /usr/local/src \
    && tar xf nginx.tar.gz \
    && unzip nginx-dav-ext-module.zip \
    && unzip headers-more-nginx-module.zip \
    && ls /usr/local/src \
    && cd nginx-${nginx_version} \
    && ./configure \
      --prefix=/usr/share/nginx \
      --sbin-path=/usr/sbin/nginx \
      --conf-path=/etc/nginx/nginx.conf \
      --pid-path=/var/run/nginx.pid \
      --lock-path=/var/lock/nginx.lock \
      --error-log-path=/var/log/nginx/error.log \
      --http-log-path=/var/log/http-access.log \
      --user=nginx \
      --group=nginx \
      --with-ipv6 \
      --with-http_v2_module \
      --with-http_dav_module \
      --with-http_gzip_static_module \
      --with-http_perl_module \
      --with-http_perl_module \
      --add-module=/usr/local/src/nginx-dav-ext-module-${nginx_dav_ext_module_version} \
      --add-module=/usr/local/src/headers-more-nginx-module-${nginx_headers_more_module_version} \
    && make build \
    && make install

FROM alpine:3.9

LABEL maintainer="Lukas Steiner <lukas.steiner@siticom.de>"
LABEL nginx_version="$nginx_version"
LABEL nginx_dav_ext_module_version="$nginx_dav_ext_module_version"
LABEL nginx_headers_more_module_version="$nginx_headers_more_module_version"

RUN apk --no-cache add libxml2 libxslt pcre perl \
    && mkdir /var/log/nginx \
    && addgroup -g 101 -S nginx \
    && adduser -u 100 -D -H -S -G nginx nginx

COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /usr/share/nginx /usr/share/nginx
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /usr/local/lib/perl5 /usr/local/lib/perl5
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
VOLUME /webdav

CMD chown nginx:nginx /webdav && nginx -g "daemon off;"