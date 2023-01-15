FROM registry.nidi.to/base-operator:latest
ENV TF_VERSION=1.3.5
ARG TARGETARCH

RUN export TARGETARCH=${TARGETARCH} && \
  curl -L -o terraform.zip https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_${TARGETARCH}.zip && \
  unzip terraform.zip && \
  mv terraform /usr/bin && \
  rm -rf terraform.zip

ADD runtime /runtime
WORKDIR /runtime
ENTRYPOINT [ "milpa", "ssl", "renew" ]
