FROM phusion/baseimage:0.11
CMD ["/sbin/my_init", "--quiet"]

MAINTAINER Kyle Wilcox <kyle@axiomdatascience.com>
ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8

ENV PYTHON_VERSION 3.7
ENV MINICONDA_VERSION latest

ENV PYCSW_VERSION 2.4.1
ENV PYCSW_ROOT /opt/pycsw
ENV PYCSW_STORE_ROOT /store
ENV PYCSW_FORCE_ROOT /force
ENV PYCSW_EXPORT_ROOT /export
ENV PYCSW_DB_ROOT /database
ENV CONDA_ROOT /opt/conda
ENV PATH ${CONDA_ROOT}/bin:$PATH

RUN apt-get update && apt-get install -y \
        binutils \
        build-essential \
        bzip2 \
        ca-certificates \
        git \
        libglib2.0-0 \
        libsm6 \
        libxext6 \
        libxrender1 \
        wget \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    mkdir -p \
        ${PYCSW_STORE_ROOT} \
        ${PYCSW_FORCE_ROOT} \
        ${PYCSW_EXPORT_ROOT} \
        ${PYCSW_DB_ROOT} \
        ${CONDA_ROOT} \
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
        ${CONDA_ROOT} \
        && \
    echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh

USER pycsw
WORKDIR ${PYCSW_ROOT}

RUN curl -k -o ./miniconda.sh https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    /bin/bash ./miniconda.sh -b -u -p ${CONDA_ROOT} && \
    rm ./miniconda.sh && \
    ${CONDA_ROOT}/bin/conda config \
        --set always_yes yes \
        --set changeps1 no \
        --set show_channel_urls True \
        && \
    ${CONDA_ROOT}/bin/conda config \
        --add channels conda-forge \
        && \
    ${CONDA_ROOT}/bin/conda install \
        python==${PYTHON_VERSION} \
        gunicorn \
        shapely \
        SQLAlchemy \
        psycopg2 \
        && \
    ${CONDA_ROOT}/bin/conda install --only-deps \
        pycsw==${PYCSW_VERSION} \
        && \
    ${CONDA_ROOT}/bin/pip install ${PYCSW_ROOT} && \
    ${CONDA_ROOT}/bin/conda clean -a -y

# Setup pycsw config
COPY default.cfg ${PYCSW_ROOT}/default.cfg

USER root

# Setup crontab
COPY crontab/* /etc/cron.d/
# Fix for hard-linked cron files
RUN echo "#!/bin/bash\ntouch /etc/crontab /etc/cron.d/*" >> /etc/my_init.d/touch-crond && chmod 744 /etc/my_init.d/touch-crond

# Setup executable scripts
COPY scripts/* /usr/local/bin/

# Setup pycsw service
COPY pycsw.sh /etc/service/pycsw/run

EXPOSE 8000/TCP
