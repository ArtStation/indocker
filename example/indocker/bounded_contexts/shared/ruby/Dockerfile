FROM ruby:2.5.0

RUN dpkg --add-architecture i386 \
  && apt-get update \
  && apt-get install vim curl -y \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir /app
WORKDIR /app
