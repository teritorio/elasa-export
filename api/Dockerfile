FROM ruby:3.1-alpine

RUN apk add --no-cache --virtual build-dependencies build-base ruby-dev ruby-json

WORKDIR /srv/app

ADD Gemfile Gemfile.lock ./
RUN bundle config --global silence_root_warning 1
RUN bundle install

ADD *.rb ./

EXPOSE 4567
VOLUME /data/config.yaml
CMD bundle exec thin -p 4567 start
