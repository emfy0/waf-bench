FROM debian:stable-slim

ARG NGINX_VERSION=1.26.0
ARG BASE_DOWNLOAD_DIR=/tmp/downloads

RUN apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -yqq  \
    automake \
    libtool \
    m4 \
    bash \
    git \
    cmake \
    make \
    tar \
    build-essential \
    libpcre3 \
    libpcre3-dev \
    zlib1g \
    zlib1g-dev \
    libssl-dev \
    libgd-dev \
    libxml2 \
    libxml2-dev \
    uuid-dev

WORKDIR $BASE_DOWNLOAD_DIR

RUN git config --global http.sslVerify false

RUN git clone --depth 1 -b v3/master --single-branch https://github.com/owasp-modsecurity/ModSecurity.git

WORKDIR $BASE_DOWNLOAD_DIR/ModSecurity

RUN git submodule init
RUN git submodule update
RUN ./build.sh
RUN ./configure
RUN make
RUN make install

WORKDIR $BASE_DOWNLOAD_DIR

RUN apt install wget -qqy

RUN git clone --depth 1 https://github.com/owasp-modsecurity/ModSecurity-nginx.git

RUN wget http://nginx.org/download/nginx-$NGINX_VERSION.tar.gz
RUN tar zxvf nginx-$NGINX_VERSION.tar.gz
WORKDIR $BASE_DOWNLOAD_DIR/nginx-$NGINX_VERSION
RUN ./configure \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --with-compat \
    --add-dynamic-module=../ModSecurity-nginx

RUN make
RUN make install
RUN make modules

RUN cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules

# COPY nginx.conf /etc/nginx/nginx.conf
COPY modesecurity/waf /usr/local/modsecurity
