# syntax=docker/dockerfile:1

ARG RUBY_VERSION=3.4.7

FROM ruby:${RUBY_VERSION}-slim AS base

WORKDIR /rails

# Packages needed to build native gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libffi-dev \
      libpq-dev \
      libyaml-dev \
      pkg-config && \
    rm -rf /var/lib/apt/lists/*

ENV RAILS_ENV=production \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_SILENCE_ROOT_WARNING=1

FROM base AS build

RUN gem install bundler:4.0.12

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Copy application code
COPY . .

# Precompile assets for production
RUN SECRET_KEY_BASE_DUMMY=1 \
    REDIS_URL=redis://127.0.0.1:6379/0 \
    bundle exec rails assets:precompile && \
    rm -rf tmp/cache

FROM ruby:${RUBY_VERSION}-slim AS runtime

WORKDIR /rails

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y ca-certificates libpq5 && \
    rm -rf /var/lib/apt/lists/* && \
    groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p storage tmp/cache tmp/pids log

ENV RAILS_ENV=production \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT="development:test" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    PATH="/rails/bin:$PATH"

COPY --from=build --chown=rails:rails /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=rails:rails /rails /rails

RUN chmod +x bin/docker-entrypoint

USER rails

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD ruby -rnet/http -e 'Net::HTTP.get_response(URI("http://127.0.0.1:3000/up"))' || exit 1

ENTRYPOINT ["./bin/docker-entrypoint"]
CMD ["./bin/rails", "server"]
