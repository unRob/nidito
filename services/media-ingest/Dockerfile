FROM registry.nidi.to/base:latest

ENV XDG_CONFIG_HOME=/config
COPY --from=rclone/rclone:latest /usr/local/bin/rclone /usr/local/bin/
RUN apk --no-cache add ca-certificates fuse jq curl

ADD sync.sh .

CMD [ "./sync.sh" ]
