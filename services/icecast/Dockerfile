FROM alpine

ENV IC_VERSION "2.4.0-kh15"

RUN addgroup icecast && \
    adduser -D -G icecast icecast && \
    apk add --no-cache --virtual .build-deps curl git autoconf make build-base curl-dev libtheora-dev libvorbis-dev libogg-dev libxslt-dev libxml2-dev speex-dev && \
    apk add --no-cache curl libtheora libvorbis libogg libxslt libxml2 speex

RUN wget "https://github.com/karlheyes/icecast-kh/archive/icecast-$IC_VERSION.tar.gz" -O- | tar zxvf - && \
	cd "icecast-kh-icecast-$IC_VERSION" && \
	./configure --prefix=/usr --sysconfdir=/etc --localstatedir=/var && \
	make && make install

RUN apk del --no-cache .build-deps

COPY --from=minio/mc /usr/bin/mc /usr/local/bin/
COPY --chown=icecast:icecast on-disconnect.sh /home/icecast/on-disconnect.sh
COPY --chown=icecast:icecast web/* /usr/share/icecast/web/

CMD ["icecast", "-c", "/etc/icecast.xml"]
