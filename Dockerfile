FROM ruby:2.5.1-alpine3.7
LABEL maintainer="Carl Mercier <foss@carlmercier.com>"

ENV ROUTER_PLUG_IP="10.0.0.241" \
    MODEM_PLUG_IP="10.0.0.242"

WORKDIR /app

COPY ["docker-files/run.sh", "/usr/local/bin/"]

RUN bundle config --global frozen 1 && \
    apk update && \
    apk add --update git nodejs nodejs-npm dumb-init && \
    npm install -g tplink-smarthome-api && \
    rm -rf /var/cache/apk/* && \
    git clone https://github.com/cmer/forever-internets.git /app && \
    cd /app && bundle

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/run.sh"]