FROM phusion/baseimage:0.10.1
CMD ["/sbin/my_init", "--quiet"]

MAINTAINER Kyle Wilcox <kyle@axiomdatascience.com>
ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8

ENV PYCSW_VERSION 2.2.0
ENV PYCSW_ROOT /opt/pycsw
ENV PYCSW_STORE_ROOT /store
ENV PYCSW_FORCE_ROOT /force
ENV PYCSW_EXPORT_ROOT /export
ENV PYCSW_DB_ROOT /database
ENV PYCSW_CONFIG ${PYCSW_ROOT}/default.cfg

RUN apt-get update && apt-get install -y \
        build-essential \
        ca-certificates \
        git \
        libgeos-3.5.0 \
        libgeos-dev \
        libxml2 \
        libxml2-dev \
        libxslt-dev \
        postgresql-server-dev-all \
        python3 \
        python3-dev \
        python3-pip \
        python3-setuptools \
        wget \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    mkdir -p \
        ${PYCSW_STORE_ROOT} \
        ${PYCSW_FORCE_ROOT} \
        ${PYCSW_EXPORT_ROOT} \
        ${PYCSW_DB_ROOT} \
        /etc/service/pycsw \
        && \
    git clone --branch ${PYCSW_VERSION} http://github.com/geopython/pycsw.git ${PYCSW_ROOT} && \
    groupadd -r pycsw -g 1000 && \
    useradd -u 1000 -r -g pycsw -d ${PYCSW_ROOT} -s /bin/bash pycsw && \
    chown -R pycsw:pycsw \
        ${PYCSW_ROOT} \
        ${PYCSW_STORE_ROOT} \
        ${PYCSW_FORCE_ROOT} \
        ${PYCSW_EXPORT_ROOT} \
        ${PYCSW_DB_ROOT} \
        && \
    cd ${PYCSW_ROOT} && \
    pip3 install gunicorn sqlalchemy psycopg2 && \
    python3 setup.py build && \
    python3 setup.py install

# Setup executable scripts
COPY scripts/* /usr/local/bin/
# Setup pycsw service
COPY pycsw.sh /etc/service/pycsw/run
# Setup pycsw config
COPY default.cfg ${PYCSW_CONFIG}

# Setup crontab
COPY crontab/* /etc/cron.d/
# Fix for hard-linked cron files
RUN echo "#!/bin/bash\ntouch /etc/crontab /etc/cron.d/*" >> /etc/my_init.d/touch-crond && chmod 744 /etc/my_init.d/touch-crond

WORKDIR ${PYCSW_ROOT}
EXPOSE 8000/TCP
