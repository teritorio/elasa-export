FROM ruby:3.1-alpine

RUN apk add --no-cache --virtual build-dependencies build-base ruby-dev ruby-json

WORKDIR /srv/app

ADD Gemfile Gemfile.lock ./
RUN bundle config --global silence_root_warning 1
RUN bundle install

ADD *.ru *.rb  ./

VOLUME /data/config.yaml
CMD bundle exec thin -p 4567 start

EXPOSE 4567

HEALTHCHECK \
    --start-interval=1s \
    --start-period=30s \
    --interval=30s \
    --timeout=20s \
    --retries=5 \
    CMD wget --no-verbose --tries=1 -O /dev/null http://127.0.0.1:4567/up || exit 1
