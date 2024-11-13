FROM registry.nidi.to/base:latest
ARG PACKAGE_MILPA_VERSION

RUN apk --update add --no-cache curl jq ncurses less findutils bash-completion openssh-client git

COPY --from=1password/op:2 /usr/local/bin/op /usr/bin/op

RUN --mount=type=secret,id=CA_PEM mkdir -p /etc/ssl/certs \
  && cp /run/secrets/CA_PEM /etc/ssl/certs/nidito.crt \
  && cat /run/secrets/CA_PEM >> /etc/ssl/certs/ca-certificates.crt
RUN awk -v cmd='openssl x509 -noout -subject' '\
/BEGIN/{close(cmd)};{print | cmd}' < /etc/ssl/certs/ca-certificates.crt | grep -i nidito

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
RUN curl --silent --show-error --fail -L https://milpa.dev/install.sh | MILPA_VERSION=${PACKAGE_MILPA_VERSION} bash -

RUN mkdir -p /etc/bash_completion.d && \
  export SHELL=bash && \
  milpa itself install-autocomplete && \
  mv /etc/profile.d/color_prompt.sh.disabled /etc/profile.d/color_prompt.sh

COPY operator/.milpa /usr/local/lib/milpa/repos/operator
COPY operator/bootstrap.sh /etc/profile.d/bash-bootstrap.sh

ENTRYPOINT [ "bash", "-il" ]
