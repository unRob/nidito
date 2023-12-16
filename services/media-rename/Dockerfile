FROM python:3.11-alpine
ARG PACKAGE_UPSTREAM_VERSION
WORKDIR /app
RUN pip install mnamer==${PACKAGE_UPSTREAM_VERSION}

ADD entrypoint.sh /entrypoint.sh
ENTRYPOINT "/entrypoint.sh"
