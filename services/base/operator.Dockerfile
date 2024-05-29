FROM registry.nidi.to/base:latest
ARG PACKAGE_MILPA_VERSION

RUN apk --update add --no-cache curl jq ncurses less findutils bash-completion openssh-client git

RUN --mount=type=secret,id=CA_PEM mkdir -p /etc/ssl/certs && \
  cp /run/secrets/CA_PEM /etc/ssl/certs/ca-certificates.crt

ENV SHELL "/bin/bash"
RUN curl --silent --show-error --fail -L https://milpa.dev/install.sh | MILPA_VERSION=${PACKAGE_MILPA_VERSION} bash -

RUN mkdir -p /etc/bash_completion.d && \
  export SHELL=bash && \
  milpa itself install-autocomplete && \
  mv /etc/profile.d/color_prompt.sh.disabled /etc/profile.d/color_prompt.sh

COPY operator/.milpa /usr/local/lib/milpa/repos/operator
COPY operator/bootstrap.sh /etc/profile.d/bash-bootstrap.sh

COPY --from=1password/op:latest /usr/local/bin/op /usr/bin/op

ENTRYPOINT [ "bash", "-il" ]
