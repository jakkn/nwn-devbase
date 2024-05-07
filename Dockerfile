# syntax=docker/dockerfile:1
FROM index.docker.io/ubuntu:noble-20240429
LABEL maintainer "jakobknutsen@gmail.com"
RUN apt-get update \
  && runDeps="g++-multilib libsqlite3-0" \
  && buildUtils="ruby wget unzip" \
  && devTools="entr" \
  && apt-get install -y --no-install-recommends $runDeps $buildUtils $devTools \
  && apt-get clean \
  && rm -r /var/lib/apt/lists /var/cache/apt

# Install neverwinter.nim binaries
ENV NWN_NIM_VERSION=1.8.0
RUN wget https://github.com/niv/neverwinter.nim/releases/download/${NWN_NIM_VERSION}/neverwinter.linux.amd64.zip \
  && unzip neverwinter.linux.amd64.zip \
  && rm neverwinter.linux.amd64.zip \
  && mv nwn_* /usr/local/bin

# Download nwn data from https://forums.beamdog.com/discussion/67157/server-download-packages-and-docker-support
ENV NWSERVER_VERSION=8193.35-40
RUN wget https://nwn.beamdog.net/downloads/nwnee-dedicated-${NWSERVER_VERSION}.zip \
  && mkdir -p /nwn/data \
  && unzip nwnee-dedicated-${NWSERVER_VERSION}.zip -d /nwn/data \
  && rm nwnee-dedicated-${NWSERVER_VERSION}.zip
ENV NWN_ROOT=/nwn/data
ENV NWN_HOME=/home/ubuntu/nwn
RUN mkdir -p $NWN_HOME

WORKDIR /usr/local/src/nwn-devbase/
COPY . ./
RUN gem install bundler \
  && bundle install
RUN ln -s $(pwd)/build.rb /usr/local/bin/nwn-build
# Modify build.rb to ignore host environment configs
RUN echo '#!/usr/bin/env ruby\nINSTALL_DIR = ENV["NWN_ROOT"]' \
  | cat - build.rb > tmp.rb \
  && mv tmp.rb build.rb && chmod 755 build.rb

# Configure devbase user
USER ubuntu
WORKDIR /home/devbase/build
ENTRYPOINT [ "nwn-build" ]
CMD [ "pack" ]
