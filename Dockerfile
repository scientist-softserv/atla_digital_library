ARG RUBY_VERSION=2.7.8
FROM ruby:$RUBY_VERSION-alpine as builder

RUN apk add build-base
RUN wget -O - https://github.com/jemalloc/jemalloc/releases/download/5.2.1/jemalloc-5.2.1.tar.bz2 | tar -xj && \
    cd jemalloc-5.2.1 && \
    ./configure && \
    make && \
    make install

FROM ghcr.io/scientist-softserv/dev-ops/samvera:f71b284f as hyrax-base

COPY --chown=1001:101 $APP_PATH/Gemfile* /app/samvera/hyrax-webapp/
RUN bundle install --jobs "$(nproc)"
COPY --chown=1001:101 $APP_PATH/bin/db-migrate-seed.sh /app/samvera/

COPY --chown=1001:101 $APP_PATH /app/samvera/hyrax-webapp

ARG HYKU_BULKRAX_ENABLED="true"
RUN sh -l -c " \
  yarn install && \
  RAILS_ENV=production SECRET_KEY_BASE=FAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKEFAKE DB_ADAPTER=nulldb DATABASE_URL='postgresql://fake' bundle exec rake assets:precompile"
RUN ln -sf /app/samvera/branding /app/samvera/hyrax-webapp/public/branding

CMD ./bin/web

COPY --from=builder /usr/local/lib/libjemalloc.so.2 /usr/local/lib/
ENV LD_PRELOAD=/usr/local/lib/libjemalloc.so.2

FROM hyrax-base as hyrax-worker
CMD ./bin/worker
