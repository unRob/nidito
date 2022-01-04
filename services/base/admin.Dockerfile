FROM registry.nidi.to/base:latest
RUN apk add curl jq

COPY admin.sh /root/.bashrc

ENTRYPOINT [ "bash", "-i" ]
