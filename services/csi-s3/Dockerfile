FROM golang:1.16-alpine as gobuild
ARG PACKAGE_UPSTREAM_VERSION
ARG TARGETARCH

WORKDIR /build

RUN apk add curl \
  && curl -L https://github.com/ctrox/csi-s3/archive/refs/tags/${PACKAGE_UPSTREAM_VERSION}.tar.gz -o /code.tgz \
  && tar xfz /code.tgz -C /build --strip=1

RUN go get -d -v ./...
RUN CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o ./s3driver ./cmd/s3driver

FROM debian:bullseye-slim

# s3fs and some other dependencies
RUN apt-get update && \
  apt-get install -y s3fs && \
  rm -rf /var/lib/apt/lists/*

# install rclone
COPY --from=rclone/rclone:latest /usr/local/bin/rclone /usr/local/bin/

COPY --from=gobuild /build/s3driver /s3driver
ENTRYPOINT ["/s3driver"]
