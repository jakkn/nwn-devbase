FROM jakkn/nwnsc as nwnsc
FROM nimlang/nim:slim as nim
WORKDIR /tmp
RUN apt update \
    && apt install -y --no-install-recommends git bash \
    && git clone --recursive https://github.com/niv/neverwinter_utils.nim \
    && cd neverwinter_utils.nim \
    && ./build.sh \
    && mv bin/* /usr/local/bin/

FROM ubuntu:latest
LABEL maintainer "jakobknutsen@gmail.com"
RUN apt-get update \
    && runDeps="g++-multilib" \
    && buildUtils="ruby" \
    && apt-get install -y --no-install-recommends $runDeps $buildUtils \
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
# Configure devbase user
RUN adduser devbase --disabled-password --gecos "" --uid 1000
RUN echo "devbase ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN sed -i "s|^#force_color_prompt=.*|force_color_prompt=yes|" /home/devbase/.bashrc
USER devbase
WORKDIR /home/devbase/build
ENTRYPOINT [ "nwn-build" ]
CMD [ "pack" ]
