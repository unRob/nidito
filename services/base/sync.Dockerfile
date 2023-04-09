FROM golang:1.17-alpine as build
RUN export GOPATH=/go; go install github.com/minio/mc@RELEASE.2023-04-06T16-51-10Z

FROM registry.nidi.to/base:latest
COPY --from=build /go/bin/mc /bin/mc
CMD [ "exit", "2" ]
