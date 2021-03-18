FROM ubuntu:20.04

RUN apt-get update && apt-get install -y \
  locales \
  ffmpeg \
  jq \
  sqlite3 \
  language-pack-es \
  openssl \
  imagemagick \
  && rm -rf /var/lib/apt/lists/* \
  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

CMD [ "/entrypoint.sh" ]
