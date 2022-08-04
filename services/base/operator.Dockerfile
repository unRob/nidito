FROM registry.nidi.to/base:latest
RUN apk --update add --no-cache curl jq ncurses less findutils bash-completion openssh-client git

RUN mkdir -p /etc/ssl/certs && \
  curl --silent --show-error --fail -L https://cajon.nidi.to/tls/casa.pem >> /etc/ssl/certs/ca-certificates.crt

RUN curl --silent --show-error --fail -L https://milpa.dev/install.sh \
  | bash -

RUN mkdir -p /etc/bash_completion.d && \
  export SHELL=bash && \
  milpa itself shell install-autocomplete && \
  mv /etc/profile.d/color_prompt.sh.disabled /etc/profile.d/color_prompt.sh

COPY operator/.milpa /usr/local/lib/milpa/repos/operator
COPY operator/bootstrap.sh /etc/profile.d/bash-bootstrap.sh

COPY --from=1password/op:latest /usr/bin/op /usr/bin/op

SHELL [ "/bin/bash" ]
ENV SHELL "/bin/bash"
ENTRYPOINT [ "bash", "-il" ]
