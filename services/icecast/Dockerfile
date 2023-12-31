FROM registry.nidi.to/base-sync:latest
ARG PACKAGE_UPSTREAM_VERSION

RUN addgroup icecast && \
    adduser -D -G icecast icecast && \
    apk --update add --no-cache --virtual .build-deps \
      git autoconf make build-base curl-dev libtheora-dev libvorbis-dev libogg-dev libxslt-dev libxml2-dev speex-dev && \
    apk --update add --no-cache \
      curl libtheora libvorbis libogg libxslt libxml2 speex && \
    wget "https://github.com/karlheyes/icecast-kh/archive/$PACKAGE_UPSTREAM_VERSION.tar.gz" -O- | tar zxvf - && \
      cd "icecast-kh-$PACKAGE_UPSTREAM_VERSION" && \
      ./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var --disable-dependency-tracking && \
      make && make install && \
    cd ../ && \
    rm -rf "icecast-kh-$PACKAGE_UPSTREAM_VERSION" && \
    apk del --no-cache .build-deps

COPY --chown=icecast:icecast etc /etc
COPY --chown=icecast:icecast usr /usr

RUN mkdir /recordings && chown -R icecast:icecast /recordings

CMD ["icecast", "-c", "/etc/icecast.xml"]
