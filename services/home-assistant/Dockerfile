ARG PACKAGE_UPSTREAM_IMAGE
ARG PACKAGE_UPSTREAM_VERSION
FROM $PACKAGE_UPSTREAM_IMAGE:$PACKAGE_UPSTREAM_VERSION

COPY --from=rclone/rclone:latest /usr/local/bin/rclone /usr/local/bin/

# needed by meross cloud
RUN pip install meross_iot==0.4.7.3
