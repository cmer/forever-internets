FROM ruby:2.7.3-alpine3.13
LABEL maintainer="Carl Mercier <foss@carlmercier.com>"

ENV ROUTER_PLUG_IP="10.0.0.241" \
    MODEM_PLUG_IP="10.0.0.242"

WORKDIR /app

COPY ["docker-files/run.sh", "/usr/local/bin/"]

RUN apk update && \
    apk add --update build-base libffi-dev git python2 dumb-init openssl-dev && \
    rm -rf /var/cache/apk/* && \
    gem install bundler && \
    bundle config --global frozen 1 && \
    git clone https://github.com/cmer/forever-internets.git /app && \
    cd /app && bundle

ENTRYPOINT ["/usr/bin/dumb-init", "--"]
CMD ["/usr/local/bin/run.sh"]