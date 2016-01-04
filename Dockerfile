FROM debian:jessie

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
    curl \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install gosu for easy step-down from root
RUN gpg --keyserver pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN curl -o /usr/local/bin/gosu -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
    && curl -o /usr/local/bin/gosu.asc -SL "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu

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

# Setup SQLite database
RUN python bin/pycsw-admin.py -c setup_db -f default.cfg

# Setup XML record store
ENV RECORDS_ROOT /records
RUN mkdir -p $RECORDS_ROOT

# Run pycsw as the 'pycsw' user
RUN groupadd -r pycsw -g 1000
RUN useradd -u 1000 -r -g pycsw -d $PYCSW_ROOT -s /bin/bash pycsw
RUN chown -R pycsw:pycsw $PYCSW_ROOT

COPY entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

EXPOSE 8000
CMD ["gunicorn", "-b", "0.0.0.0:8000", "-w", "4", "--access-logfile", "-", "--error-logfile", "-", "pycsw.wsgi:application"]
