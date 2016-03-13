FROM ruby:2.2

RUN mkdir -p /app
WORKDIR /app

# install gems
COPY Gemfile* ./
RUN bundle

COPY . .

CMD ["./compare.rb"]
