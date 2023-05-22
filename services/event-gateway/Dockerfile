FROM golang:1.20-alpine as build
RUN apk add git
WORKDIR /src
ADD go.mod go.sum main.go /src/
RUN export GOPATH=/go; go build -ldflags "-s -w" -trimpath -o /event-gateway

FROM registry.nidi.to/base:latest
COPY --from=build /event-gateway /event-gateway

ENTRYPOINT [ "/event-gateway" ]
