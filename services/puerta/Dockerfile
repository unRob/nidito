FROM golang:1.20-alpine as build
RUN apk add --no-cache --virtual .build-deps git gcc cmake build-base make musl-dev && \
    export GOPATH=/go; go install git.rob.mx/nidito/puerta@a344574 && \
    apk del .build-deps

FROM registry.nidi.to/base:latest
COPY --from=build /go/bin/puerta /bin/puerta

ENTRYPOINT [ "/bin/puerta" ]
CMD [ "server" ]
