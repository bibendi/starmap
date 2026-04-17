FROM ruby:3.3.5-slim AS base

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      libpq5 \
      libjemalloc2 \
      libvips42 \
      curl \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV=production \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_DEPLOYMENT=1 \
    RAILS_LOG_TO_STDOUT=1

WORKDIR /app

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      libpq-dev \
      git \
      pkg-config \
      libyaml-dev \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock .ruby-version ./
COPY gemfiles/ gemfiles/
RUN bundle install && \
    rm -rf ~/.bundle /usr/local/bundle/cache/*.gem /usr/local/bundle/gems/*/spec /usr/local/bundle/gems/*/test

COPY package.json package-lock.json ./
RUN npm ci && \
    npm cache clean --force

COPY . .
RUN SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile

FROM base

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app

RUN useradd rails --create-home --shell /bin/bash && \
    chown -R rails:rails /app
USER rails

EXPOSE 3000

CMD ["/app/bin/docker-entrypoint", "bundle", "exec", "puma", "-C", "config/puma.rb"]
