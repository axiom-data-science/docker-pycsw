FROM phusion/baseimage:0.9.18
# Use baseimage-docker's init system
CMD ["/sbin/my_init"]

MAINTAINER Kyle Wilcox <kyle@axiomdatascience.com>
ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y \
    git \
    wget \
    bzip2 \
    ca-certificates \
    libglib2.0-0 \
    libxext6 \
    libsm6 \
    libxrender1 \
    pwgen \
    binutils \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Setup CONDA (https://hub.docker.com/r/continuumio/miniconda3/~/dockerfile/)
ENV MINICONDA_VERSION 3.16.0
ENV CONDA_VERSION 3.19.0
RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda-$MINICONDA_VERSION-Linux-x86_64.sh && \
    /bin/bash /Miniconda-$MINICONDA_VERSION-Linux-x86_64.sh -b -p /opt/conda && \
    rm Miniconda-$MINICONDA_VERSION-Linux-x86_64.sh && \
    /opt/conda/bin/conda install --yes conda==$CONDA_VERSION
ENV PATH /opt/conda/bin:$PATH

# Setup pycsw
ENV PYCSW_ROOT /opt/pycsw
RUN mkdir -p "$PYCSW_ROOT"
WORKDIR $PYCSW_ROOT

ENV PYCSW_VERSION master
RUN conda config --add channels ioos
RUN git clone --branch $PYCSW_VERSION http://github.com/geopython/pycsw.git .
RUN conda install --file requirements.txt
RUN conda install --file requirements-standalone.txt
RUN conda install conda-build gunicorn
RUN conda develop .

COPY default.cfg $PYCSW_ROOT/default.cfg

# Run pycsw as the 'pycsw' user
RUN groupadd -r pycsw -g 1000
RUN useradd -u 1000 -r -g pycsw -d $PYCSW_ROOT -s /bin/bash pycsw
RUN chown -R pycsw:pycsw $PYCSW_ROOT

# Setup XML record store
ENV STORE_ROOT /store
RUN mkdir -p $STORE_ROOT
RUN chown -R pycsw:pycsw $STORE_ROOT

# Setup XML record store
ENV FORCE_ROOT /force
RUN mkdir -p $FORCE_ROOT
RUN chown -R pycsw:pycsw $FORCE_ROOT

# Setup XML dump store
ENV EXPORT_ROOT /export
RUN mkdir -p $EXPORT_ROOT
RUN chown -R pycsw:pycsw $EXPORT_ROOT

# Setup crontab
COPY crontab/* /etc/cron.d/
COPY scripts/* /usr/local/bin/

# Setup service
RUN mkdir /etc/service/pycsw
COPY pycsw.sh /etc/service/pycsw/run

EXPOSE 8000
