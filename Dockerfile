# syntax=docker/dockerfile:1
FROM index.docker.io/nwneetools/nwnsc as nwnsc
FROM index.docker.io/alpine/git as git
WORKDIR /tmp
RUN git clone --recursive https://github.com/niv/neverwinter_utils.nim
FROM index.docker.io/nimlang/nim:latest as nim
WORKDIR /tmp
COPY --from=git /tmp/ /tmp
RUN cd neverwinter_utils.nim \
  && nimble build -d:release -y \
  && mv bin/* /usr/local/bin/

FROM index.docker.io/ubuntu:latest
LABEL maintainer "jakobknutsen@gmail.com"
RUN apt-get update \
  && runDeps="g++-multilib libsqlite3-0" \
  && buildUtils="ruby" \
  && devTools="entr" \
  && apt-get install -y --no-install-recommends $runDeps $buildUtils $devTools \
  && apt-get clean \
  && rm -r /var/lib/apt/lists /var/cache/apt
COPY --from=nwnsc /usr/local/bin/nwnsc /usr/local/bin/
COPY --from=nwnsc /nwn /nwn
ENV NWN_INSTALLDIR=/nwn/data
COPY --from=nim /usr/local/bin/* /usr/local/bin/
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
