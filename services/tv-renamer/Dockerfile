FROM python:3.10-alpine
WORKDIR /app

ADD requirements.txt /app/requirements.txt
RUN apk add --no-cache --virtual .build-deps git \
  && pip install setuptools \
  && pip install -r requirements.txt \
  && rm -rf .build-deps

CMD [ "tvnamer", "--config", "/app/config.json", "/media/dropbox/tv-series", "-m", "-d", "/media/tv-series/%(seriesname)s/Season %(seasonnumber)02d/" ]
