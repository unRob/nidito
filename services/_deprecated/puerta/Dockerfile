FROM golang:1.20-alpine as build
RUN apk add git gcc cmake build-base make musl-dev
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    export GOPATH=/go; go install git.rob.mx/nidito/puerta@2c276d8

FROM registry.nidi.to/base:latest
COPY --from=build /go/bin/puerta /bin/puerta

ENTRYPOINT [ "/bin/puerta" ]
CMD [ "server" ]
