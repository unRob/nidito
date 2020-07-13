FROM alpine:latest
ENV XDG_CONFIG_HOME=/config
COPY --from=rclone/rclone:latest /usr/local/bin/rclone /usr/local/bin/
RUN apk --no-cache add ca-certificates fuse jq bash

ADD sync.sh .

CMD [ "./sync.sh" ]
