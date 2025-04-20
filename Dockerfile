# syntax=docker/dockerfile:1
FROM index.docker.io/ruby:3.0.2-slim-bullseye
LABEL maintainer "jakobknutsen@gmail.com"
RUN apt-get update \
  && runDeps="g++-multilib libsqlite3-0" \
  && buildUtils="wget unzip" \
  && devTools="entr" \
  && apt-get install -y --no-install-recommends $runDeps $buildUtils $devTools \
  && apt-get clean \
  && rm -r /var/lib/apt/lists /var/cache/apt

# Install neverwinter.nim binaries
ENV NWN_NIM_VERSION=2.0.3
RUN wget https://github.com/niv/neverwinter.nim/releases/download/${NWN_NIM_VERSION}/neverwinter.linux.amd64.zip \
  && unzip neverwinter.linux.amd64.zip \
  && rm neverwinter.linux.amd64.zip \
  && mv nwn_* /usr/local/bin

ENV NWN_ROOT="/nwn/root"
ENV NWN_HOME="/nwn/home"
RUN mkdir -p $NWN_ROOT && mkdir -p $NWN_HOME
# Download nwn data from https://forums.beamdog.com/discussion/67157/server-download-packages-and-docker-support
ENV NWSERVER_VERSION=8193.36-12
RUN wget https://nwn.beamdog.net/downloads/nwnee-dedicated-${NWSERVER_VERSION}.zip \
  && mkdir -p $NWN_ROOT \
  && unzip nwnee-dedicated-${NWSERVER_VERSION}.zip -d $NWN_ROOT \
  && rm nwnee-dedicated-${NWSERVER_VERSION}.zip

WORKDIR /usr/local/src/nwn-devbase/
COPY . ./
RUN gem install bundler \
  && bundle install
RUN ln -s $(pwd)/build.rb /usr/local/bin/nwn-build

# Configure user
ARG USER=devbase
RUN adduser --disabled-password --gecos "" --uid=1000 $USER
RUN echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
RUN sed -i "s|^#force_color_prompt=.*|force_color_prompt=yes|" /home/$USER/.bashrc
USER $USER
WORKDIR /home/$USER/build
ENTRYPOINT [ "nwn-build" ]
CMD [ "pack" ]
