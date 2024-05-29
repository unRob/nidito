FROM golang:1.22-alpine as build
ARG PACKAGE_MINIO_VERSION
RUN export GOPATH=/go; go install github.com/minio/mc@$PACKAGE_MINIO_VERSION

FROM registry.nidi.to/base:latest
COPY --from=build /go/bin/mc /bin/mc
CMD [ "exit", "2" ]
