FROM golang:1.21-alpine as build
RUN export GOPATH=/go; go install github.com/minio/mc@RELEASE.2023-11-20T16-30-59Z

FROM registry.nidi.to/base:latest
COPY --from=build /go/bin/mc /bin/mc
CMD [ "exit", "2" ]
