FROM golang:1.17-alpine as build
RUN export GOPATH=/go; go install github.com/minio/mc@RELEASE.2021-12-29T06-52-55Z

FROM registry.nidi.to/base:latest
COPY --from=build /go/bin/mc /bin/mc
CMD [ "exit", "2" ]
