FROM golang:1.21-alpine as build
ARG PACKAGE_UPSTREAM_VERSION
ARG PACKAGE_UPSTREAM_SOURCE
RUN apk add git openssh
WORKDIR /src
RUN git config --global --add url.ssh://git@${PACKAGE_UPSTREAM_SOURCE#*://}.insteadOf ${PACKAGE_UPSTREAM_SOURCE}
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    --mount=type=ssh \
    mkdir ~/.ssh/ && \
    ssh-keyscan -t rsa -H git.rob.mx >> ~/.ssh/known_hosts && \
    export GOPATH=/go GOPRIVATE=${PACKAGE_UPSTREAM_SOURCE#*://}; go install ${PACKAGE_UPSTREAM_SOURCE#*://}@${PACKAGE_UPSTREAM_VERSION}

FROM registry.nidi.to/base:latest
COPY --from=build /go/bin/event-gateway /event-gateway

ENTRYPOINT [ "/event-gateway", "server", "--verbose" ]
