ARG PACKAGE_POSTGRES_VERSION
FROM postgres:${PACKAGE_POSTGRES_VERSION:-16.4}
# buildkit complains about an unset version unless I set that default, which is likely the argument
ARG PACKAGE_POSTGRES_VERSION=${PACKAGE_POSTGRES_VERSION}
ARG PACKAGE_POSTGIS_VERSION
ARG PACKAGE_PATRONI_VERSION

ENV PGHOME=/home/postgres
# copy pasta from:
# https://github.com/ccakes/nomad-pgsql-patroni/blob/master/Dockerfile
# https://github.com/patroni/patroni/blob/master/kubernetes/Dockerfile

RUN export DEBIAN_FRONTEND=noninteractive \
  && echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";\nAcquire::http::Pipeline-Depth 0;\nAcquire::http::No-Cache true;\nAcquire::BrokenProxy    true;Acquire::CompressionTypes::Order::=gz;'  > /etc/apt/apt.conf.d/01norecommend \
  && apt update \
  && apt-cache depends patroni | sed -n -e 's/.* Depends: \(python3-.\+\)$/\1/p' \
          | grep -Ev '^python3-consul' \
          | xargs apt-get install -y locales python3-pip python3-wheel curl \
  ## Make sure we have a en_US.UTF-8 locale available
  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
  && pip3 install --break-system-packages 'patroni[consul]=='${PACKAGE_PATRONI_VERSION} \
  && mkdir -p ${PGHOME} \
  && chown postgres ${PGHOME} \
  && sed -i "s|/var/lib/postgresql.*|${PGHOME}:/bin/bash|" /etc/passwd \
  # Set permissions for OpenShift
  && chmod 775 ${PGHOME} \
  && chmod 664 /etc/passwd \
  # Clean up
  && apt-get remove -y python3-pip python3-wheel \
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/* /root/.cache

COPY entrypoint.sh /

EXPOSE 5432 8008
ENV LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8 EDITOR=/usr/bin/editor
WORKDIR /home/postgres


ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
