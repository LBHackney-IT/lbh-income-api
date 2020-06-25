FROM ruby:2.5.3

ARG RAILS_ENV=development
WORKDIR /app

# 50 MB stack needed in sync worker thread
ENV RUBY_THREAD_VM_STACK_SIZE=50000000

RUN wget -q https://www.freetds.org/files/stable/freetds-1.00.27.tar.gz && \
  tar -xzf freetds-1.00.27.tar.gz && \
  cd freetds-1.00.27 && \
  ./configure --prefix=/usr/local --with-tdsver=7.3 && \
  make && \
  make install

ENV DOCKERIZE_VERSION=v0.3.0
RUN wget --quiet https://github.com/jwilder/dockerize/releases/download/$DOCKERIZE_VERSION/dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
 tar -C /usr/local/bin -xzvf dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz && \
 rm dockerize-linux-amd64-$DOCKERIZE_VERSION.tar.gz

ENV RAILS_ENV ${RAILS_ENV}

COPY Gemfile Gemfile.lock ./
RUN gem install bundler:1.17.3
RUN bundle check || bundle install

# Add a script to be executed every time the container starts.
COPY bin/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

COPY . /app
EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
