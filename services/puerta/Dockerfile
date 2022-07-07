FROM golang:1.17-alpine as build
COPY http /go/src/github.com/unRob/nidito/services/puerta/http
RUN export GOPATH=/go; cd /go/src/github.com/unRob/nidito/services/puerta/http && go build -o /bin/puerta

FROM registry.nidi.to/base:latest
COPY --from=build /bin/puerta /bin/puerta

ENTRYPOINT [ "/bin/puerta" ]
