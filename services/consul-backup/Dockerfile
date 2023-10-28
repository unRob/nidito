FROM busybox:latest as buildenv
ARG TARGETARCH
ARG CONSUL_VERSION=1.15.2

WORKDIR /unpack
RUN \
  wget -O consul.zip "https://releases.hashicorp.com/consul/${CONSUL_VERSION}/consul_${CONSUL_VERSION}_linux_$TARGETARCH.zip" \
  && ls -lah consul.zip \
  && unzip -d /usr/bin/ ./consul.zip \
  && rm -rf consul.zip

FROM registry.nidi.to/base-sync:latest
COPY --from=buildenv /usr/bin/consul /usr/bin/consul
RUN apk add --no-cache age
COPY entrypoint.sh entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]
