FROM registry.nidi.to/base-operator:latest
ARG PACKAGE_TERRAFORM_VERSION
ARG TARGETARCH

RUN export TARGETARCH=${TARGETARCH} && \
  curl -L -o terraform.zip https://releases.hashicorp.com/terraform/${PACKAGE_TERRAFORM_VERSION}/terraform_${PACKAGE_TERRAFORM_VERSION}_linux_${TARGETARCH}.zip && \
  unzip terraform.zip && \
  mv terraform /usr/bin && \
  rm -rf terraform.zip && apk add bind-tools

ADD runtime /runtime
WORKDIR /runtime
ENTRYPOINT [ "milpa", "ssl", "renew" ]
