# syntax=docker/dockerfile:1
FROM index.docker.io/beamdog/nwserver:8193.34 as nwserver

FROM index.docker.io/ubuntu:focal
LABEL maintainer "jakobknutsen@gmail.com"
RUN apt-get update \
  && runDeps="g++-multilib libsqlite3-0" \
  && buildUtils="ruby wget unzip" \
  && devTools="entr" \
  && apt-get install -y --no-install-recommends $runDeps $buildUtils $devTools \
  && apt-get clean \
  && rm -r /var/lib/apt/lists /var/cache/apt
# Install neverwinter.nim binaries
RUN wget https://github.com/niv/neverwinter.nim/releases/download/1.5.6/neverwinter.linux.amd64.zip \
  && unzip neverwinter.linux.amd64.zip \
  && rm neverwinter.linux.amd64.zip \
  && mv nwn_* /usr/local/bin
# Install nwnsc binary
RUN wget https://github.com/nwneetools/nwnsc/releases/download/v1.1.3/nwnsc-linux-v1.1.3.zip \
  && unzip nwnsc-linux-v1.1.3.zip \
  && rm nwnsc-linux-v1.1.3.zip \
  && mv nwnsc /usr/local/bin/
COPY --from=nwserver /nwn /nwn
ENV NWN_INSTALLDIR=/nwn/data
WORKDIR /usr/local/src/nwn-devbase/
COPY . ./
# Default Rubygems on debian is bugged and messes up paths.
# Ref: https://github.com/rubygems/rubygems/issues/2180
RUN gem update --system
RUN gem install bundler \
  && bundle install
RUN ln -s $(pwd)/build.rb /usr/local/bin/nwn-build
# Modify build.rb to ignore host environment configs
RUN echo '#!/usr/bin/env ruby\nINSTALL_DIR = ENV["NWN_INSTALLDIR"]' \
  | cat - build.rb > tmp.rb \
  && mv tmp.rb build.rb && chmod 755 build.rb
# Configure devbase user
RUN adduser devbase --disabled-password --gecos "" --uid 1000
RUN echo "devbase ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN sed -i "s|^#force_color_prompt=.*|force_color_prompt=yes|" /home/devbase/.bashrc
WORKDIR /home/devbase/build
RUN chown devbase:devbase .
USER devbase
ENTRYPOINT [ "nwn-build" ]
CMD [ "pack" ]
