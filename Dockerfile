FROM ruby:2.5.1
WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle check || bundle install
