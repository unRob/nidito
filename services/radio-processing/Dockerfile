FROM registry.nidi.to/base-sync:latest

RUN apk --update add --no-cache \
  ffmpeg \
  jq \
  sqlite

CMD [ "/entrypoint.sh" ]
