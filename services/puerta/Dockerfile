FROM golang:1.20-alpine as build
RUN apk add git gcc cmake build-base make musl-dev
RUN export GOPATH=/go; go install git.rob.mx/nidito/puerta@a344574

FROM registry.nidi.to/base:latest
COPY --from=build /go/bin/puerta /bin/puerta

ENTRYPOINT [ "/bin/puerta" ]
CMD [ "server" ]
