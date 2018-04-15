FROM beamdog/nwserver:latest as nwserver

FROM ubuntu:latest
LABEL maintainer "jakobknutsen@gmail.com"
WORKDIR /home/devbase
RUN apt-get update
RUN buildDeps="curl gcc libc-dev xz-utils git" \
    && buildUtils="ruby" \
    && apt-get install -y --no-install-recommends $buildDeps $buildUtils 
RUN curl -sSfo /tmp/init.sh https://nim-lang.org/choosenim/init.sh && sh /tmp/init.sh -y 
RUN git clone --recursive https://github.com/niv/neverwinter_utils.nim 
ENV PATH="/root/.nimble/bin:${PATH}"
RUN cd neverwinter_utils.nim \
    && ./build.sh \
    && mv bin/* /usr/local/bin/ \
    && cd ..
# && rm -rf /tmp/* \
# && apt-get purge $buildDeps \
# && apt-get clean \
# && rm -r /var/lib/apt/lists /var/cache/apt
COPY --from=nwserver /nwn/data /nwn/data
WORKDIR /home/devbase
COPY ./*.rb ./config.rb.in ./*.rake ./Gemfile* ./scripts ./
RUN gem install bundler \
    && bundle install
ENTRYPOINT [ "ruby",  "build.rb" ]
CMD [ "pack" ]
