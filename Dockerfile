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
RUN gem update --system 2.7.7
RUN gem install bundler \
    && bundle install
# Rubygems on debian messes up paths. Temporary workaround.
# Ref: https://github.com/rubygems/rubygems/issues/2180
RUN rm /usr/local/bin/rake && ln -s /usr/bin/rake /usr/local/bin/rake
RUN ruby build.rb install
WORKDIR /devbase
ENTRYPOINT [ "nwn-build" ]
CMD [ "pack" ]
