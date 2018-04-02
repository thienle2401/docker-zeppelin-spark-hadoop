FROM gettyimages/spark:2.1.1-hadoop-2.7

# SciPy
RUN set -ex \
 && buildDeps=' \
    libpython3-dev \
    build-essential \
    pkg-config \
    gfortran \
 ' \
 && apt-get update && apt-get install -y --no-install-recommends \
    $buildDeps \
    ca-certificates \
    wget \
    liblapack-dev \
    libopenblas-dev \
 && packages=' \
    numpy \
    pandasql \
    scipy \
 ' \
 && pip3 install $packages \
 && rm -rf /root/.cache/pip \
 && apt-get purge -y --auto-remove $buildDeps \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*


# install R ##########################
######################################
RUN apt-get update && apt-get install -y r-base r-base-dev libssl-dev libcurl4-openssl-dev \
 && R -e "install.packages('devtools', repos = 'http://cran.us.r-project.org')" \
 && R -e "install.packages('knitr', repos = 'http://cran.us.r-project.org')" \
 && R -e "install.packages('ggplot2', repos = 'http://cran.us.r-project.org')" \
 && R -e "install.packages('dplyr', repos = 'http://cran.us.r-project.org')" \
 && R -e "install.packages('corrplot', repos = 'http://cran.us.r-project.org')" \
 && R -e "install.packages('reshape', repos = 'http://cran.us.r-project.org')" \
 && R -e "install.packages(c('devtools','mplot', 'googleVis'), repos = 'http://cran.us.r-project.org'); require(devtools); install_github('ramnathv/rCharts')"


# Zeppelin
ENV ZEPPELIN_PORT 8080
ENV ZEPPELIN_HOME /zeppelin
ENV ZEPPELIN_CONF_DIR $ZEPPELIN_HOME/conf
ENV ZEPPELIN_NOTEBOOK_DIR $ZEPPELIN_HOME/notebook

ENV Z_VERSION="0.7.3"
ENV LOG_TAG="[ZEPPELIN_${Z_VERSION}]:" \
    Z_HOME="/zeppelin" \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN echo "$LOG_TAG Download Zeppelin binary" && \
    wget -O /tmp/zeppelin-${Z_VERSION}-bin-all.tgz http://archive.apache.org/dist/zeppelin/zeppelin-${Z_VERSION}/zeppelin-${Z_VERSION}-bin-all.tgz && \
    tar -zxvf /tmp/zeppelin-${Z_VERSION}-bin-all.tgz && \
    rm -rf /tmp/zeppelin-${Z_VERSION}-bin-all.tgz && \
    mv zeppelin-${Z_VERSION}-bin-all ${Z_HOME}

ADD about.json $ZEPPELIN_NOTEBOOK_DIR/2BTRWA9EV/note.json
WORKDIR $ZEPPELIN_HOME
CMD ["bin/zeppelin.sh"]
