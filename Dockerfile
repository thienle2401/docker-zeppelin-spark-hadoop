FROM ubuntu:16.04

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

# basic system configurations #
###############################
RUN echo "update and install basic packages" \
    && apt-get -y update \
    && apt-get install -y locales \
    && locale-gen $LANG \
    && apt-get install -y software-properties-common \
    && apt -y autoclean \
    && apt -y dist-upgrade \
    && apt-get install -y build-essential \
    && apt-get install -y --no-install-recommends git \
    && apt-get install -y --no-install-recommends maven \
    && apt-get install -y --no-install-recommends npm \
    && apt-get install -y --no-install-recommends bzip2 \
    && apt-get install -y --no-install-recommends curl

RUN echo "install tini related packages" \
    && apt-get install -y wget curl grep sed dpkg \
    && TINI_VERSION=`curl https://github.com/krallin/tini/releases/latest | grep -o "/v.*\"" | sed 's:^..\(.*\).$:\1:'` \
    && curl -L "https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini_${TINI_VERSION}.deb" > tini.deb \
    && dpkg -i tini.deb \
    && rm tini.deb

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
RUN echo "install java8" \
  && apt-get -y update \
  && apt-get install -y openjdk-8-jdk


# install Apache Hadoop #
#########################
WORKDIR /temp

ENV HADOOP_VERSION="2.7.3"
ENV HADOOP_FILE_BINARY="hadoop-${HADOOP_VERSION}.tar.gz"
ENV HADOOP_DOWNLOAD_URL="http://archive.apache.org/dist/hadoop/common/hadoop-${HADOOP_VERSION}/${HADOOP_FILE_BINARY}"
ENV HADOOP_HOME=/usr/hadoop-$HADOOP_VERSION
ENV HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop
ENV PATH=$PATH:$HADOOP_HOME/bin

RUN curl -sL $HADOOP_DOWNLOAD_URL \
    | gunzip \
    | tar x -C /usr/ \
    && rm -rf $HADOOP_HOME/share/doc \
    && chown -R root:root $HADOOP_HOME \
    && rm -rf HADOOP_FILE_BINARY

# install Apache Spark #
########################
WORKDIR /temp

ENV SPARK_VERSION="2.1.1"
ENV SPARK_HADOOP_VERSION="hadoop2.7"
ENV SPARK_HOME="/usr/spark-${SPARK_VERSION}"
ENV SPARK_FILE_BINARY="spark-${SPARK_VERSION}-bin-${SPARK_HADOOP_VERSION}.tgz"
ENV SPARK_DOWNLOAD_URL="https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/${SPARK_FILE_BINARY}"
ENV SPARK_DIST_CLASSPATH="$HADOOP_HOME/etc/hadoop/*:$HADOOP_HOME/share/hadoop/common/lib/*:$HADOOP_HOME/share/hadoop/common/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/hdfs/lib/*:$HADOOP_HOME/share/hadoop/hdfs/*:$HADOOP_HOME/share/hadoop/yarn/lib/*:$HADOOP_HOME/share/hadoop/yarn/*:$HADOOP_HOME/share/hadoop/mapreduce/lib/*:$HADOOP_HOME/share/hadoop/mapreduce/*:$HADOOP_HOME/share/hadoop/tools/lib/*"
ENV PATH=$PATH:${SPARK_HOME}/bin

RUN curl -sL --retry 3 \
  $SPARK_DOWNLOAD_URL \
  | gunzip \
  | tar x -C /usr/ \
 && mv /usr/spark-${SPARK_VERSION}-bin-${SPARK_HADOOP_VERSION} $SPARK_HOME \
 && chown -R root:root $SPARK_HOME \
 && rm -rf $SPARK_FILE_BINARY


# install R and essential packages #
####################################
RUN echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" | tee -a /etc/apt/sources.list \
    && gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 \
    && gpg -a --export E084DAB9 | apt-key add -  \
    && apt-get -y update \
    && apt-get install -y r-base r-base-dev libssl-dev libcurl4-openssl-dev \
    && R -e "install.packages('devtools', repos = 'http://cran.us.r-project.org')" \
    && R -e "install.packages('knitr', repos = 'http://cran.us.r-project.org')" \
    && R -e "install.packages('ggplot2', repos = 'http://cran.us.r-project.org')" \
    && R -e "install.packages('dplyr', repos = 'http://cran.us.r-project.org')" \
    && R -e "install.packages('corrplot', repos = 'http://cran.us.r-project.org')" \
    && R -e "install.packages('reshape', repos = 'http://cran.us.r-project.org')" \
    && R -e "install.packages(c('devtools','mplot', 'googleVis'), repos = 'http://cran.us.r-project.org')" \
    && R -e "require(devtools); install_github('ramnathv/rCharts')"


# install Apache Zeppelin from source #
#######################################
ENV Z_VERSION="branch-0.8-root" \
    Z_HOME="/usr/zeppelin" \
    Z_SOURCE="/usr/src/zeppelin"

ENV ZEPPELIN_CONF_DIR=$Z_HOME/conf \
    ZEPPELIN_NOTEBOOK_DIR=$Z_HOME/notebook

WORKDIR $Z_SOURCE

RUN git clone --branch $Z_VERSION https://github.com/thienle2401/zeppelin.git $Z_SOURCE

RUN dev/change_scala_version.sh 2.11 \
    && mvn clean package -Pspark-2.1 -Pr -Pscala-2.11 -Dcheckstyle.skip -DskipTests -Pbuild-distr \
    && tar xvf $Z_SOURCE/zeppelin-distribution/target/zeppelin*.tar.gz -C /usr/ \
    && mv /usr/zeppelin* $Z_HOME \
    && mkdir -p $ZEPPELIN_HOME/logs \
    && mkdir -p $ZEPPELIN_HOME/run

# clean up #
############
RUN rm -rf /var/lib/apt/lists/* \
    && rm -rf $Z_SOURCE \
    && rm -rf /root/.m2 \
    && rm -rf /root/.npm  \
    && rm -rf /root/.cache/bower \
    && rm -rf /tmp/*


# set command to install zeppelin
WORKDIR $Z_HOME
CMD ["bin/zeppelin.sh"]
