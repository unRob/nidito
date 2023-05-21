FROM python:3.10-alpine
WORKDIR /app

ADD requirements.txt /app/requirements.txt
RUN apk add --no-cache --virtual .build-deps git \
  && pip install setuptools \
  && pip install -r requirements.txt \
  && rm -rf .build-deps

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT "/entrypoint.sh"
