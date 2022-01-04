FROM alpine:latest
ENV MUSL_LOCPATH /usr/local/share/i18n/locales/musl

RUN apk --update add --no-cache \
  coreutils \
  openssl \
  tzdata \
  bash

RUN apk add --no-cache --virtual .build-deps \
  build-base \
  cmake \
  gcc \
  gettext-dev \
  git \
  libintl \
  make \
  musl-dev && \
    git clone https://gitlab.com/rilian-la-te/musl-locales.git \
    && cd musl-locales \
      && git checkout 1101fb2bcdd189cd9415b8bd1c775eb43527d25c \
      && sed 's/^msgstr "aug"/msgstr "ago"/; s/msgstr "augosto"/msgstr "agosto"/; s/msgstr "may"/msgstr "mayo"/; s/msgstr "miercoles"/msgstr "miércoles"/; s/msgstr "sabado"/msgstr "sábado"/' musl-po/es_ES.po > musl-po/es_MX.po \
      && cmake . \
      && make \
      && make install \
    && cd ../ \
    && rm -rf musl-locales \
    && apk del .build-deps

CMD [ "echo" "no command specified" ]
