FROM gettyimages/spark:2.2.1-hadoop-2.7

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


 ## Install R
 ARG R_VERSION
 ARG BUILD_DATE
 ENV R_VERSION=${R_VERSION:-3.4.3} \
     LC_ALL=en_US.UTF-8 \
     LANG=en_US.UTF-8 \
     TERM=xterm

 RUN apt-get update \
   && apt-get install -y --no-install-recommends \
     bash-completion \
     ca-certificates \
     file \
     fonts-texgyre \
     g++ \
     gfortran \
     gsfonts \
     libblas-dev \
     libbz2-1.0 \
     libcurl3 \
     libicu57 \
     libjpeg62-turbo \
     libopenblas-dev \
     libpangocairo-1.0-0 \
     libpcre3 \
     libpng16-16 \
     libreadline7 \
     libtiff5 \
     liblzma5 \
     locales \
     make \
     unzip \
     zip \
     zlib1g \
   && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
   && locale-gen en_US.utf8 \
   && /usr/sbin/update-locale LANG=en_US.UTF-8 \
   && BUILDDEPS="curl \
     default-jdk \
     libbz2-dev \
     libcairo2-dev \
     libcurl4-openssl-dev \
     libpango1.0-dev \
     libjpeg-dev \
     libicu-dev \
     libpcre3-dev \
     libpng-dev \
     libreadline-dev \
     libtiff5-dev \
     liblzma-dev \
     libx11-dev \
     libxt-dev \
     perl \
     tcl8.6-dev \
     tk8.6-dev \
     texinfo \
     texlive-extra-utils \
     texlive-fonts-recommended \
     texlive-fonts-extra \
     texlive-latex-recommended \
     x11proto-core-dev \
     xauth \
     xfonts-base \
     xvfb \
     zlib1g-dev" \
   && apt-get install -y --no-install-recommends $BUILDDEPS \
   && cd tmp/ \
   ## Download source code
   && curl -O https://cran.r-project.org/src/base/R-3/R-${R_VERSION}.tar.gz \
   ## Extract source code
   && tar -xf R-${R_VERSION}.tar.gz \
   && cd R-${R_VERSION} \
   ## Set compiler flags
   && R_PAPERSIZE=letter \
     R_BATCHSAVE="--no-save --no-restore" \
     R_BROWSER=xdg-open \
     PAGER=/usr/bin/pager \
     PERL=/usr/bin/perl \
     R_UNZIPCMD=/usr/bin/unzip \
     R_ZIPCMD=/usr/bin/zip \
     R_PRINTCMD=/usr/bin/lpr \
     LIBnn=lib \
     AWK=/usr/bin/awk \
     CFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
     CXXFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
   ## Configure options
   ./configure --enable-R-shlib \
                --enable-memory-profiling \
                --with-readline \
                --with-blas \
                --with-tcltk \
                --disable-nls \
                --without-recommended-packages \
   ## Build and install
   && make \
   && make install \
   ## Add a default CRAN mirror
   && echo "options(repos = c(CRAN = 'https://cran.rstudio.com/'), download.file.method = 'libcurl')" >> /usr/local/lib/R/etc/Rprofile.site \
   ## Add a library directory (for user-installed packages)
   && mkdir -p /usr/local/lib/R/site-library \
   && chown root:staff /usr/local/lib/R/site-library \
   && chmod g+wx /usr/local/lib/R/site-library \
   ## Fix library path
   && echo "R_LIBS_USER='/usr/local/lib/R/site-library'" >> /usr/local/lib/R/etc/Renviron \
   && echo "R_LIBS=\${R_LIBS-'/usr/local/lib/R/site-library:/usr/local/lib/R/library:/usr/lib/R/library'}" >> /usr/local/lib/R/etc/Renviron \
   ## install packages from date-locked MRAN snapshot of CRAN
   && [ -z "$BUILD_DATE" ] && BUILD_DATE=$(TZ="America/Los_Angeles" date -I) || true \
   && MRAN=https://mran.microsoft.com/snapshot/${BUILD_DATE} \
   && echo MRAN=$MRAN >> /etc/environment \
   && export MRAN=$MRAN \
   ## MRAN becomes default only in versioned images
   ## Use littler installation scripts
   && Rscript -e "install.packages(c('littler', 'docopt'), repo = '$MRAN')" \
   && ln -s /usr/local/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r \
   && ln -s /usr/local/lib/R/site-library/littler/examples/installGithub.r /usr/local/bin/installGithub.r \
   && ln -s /usr/local/lib/R/site-library/littler/bin/r /usr/local/bin/r \
   ## TEMPORARY WORKAROUND to get more robust error handling for install2.r prior to littler update
   && curl -O /usr/local/bin/install2.r https://github.com/eddelbuettel/littler/raw/master/inst/examples/install2.r \
   && chmod +x /usr/local/bin/install2.r \
   ## Clean up from R source install
   && cd / \
   && rm -rf /tmp/* \
   && apt-get remove --purge -y $BUILDDEPS \
   && apt-get autoremove -y \
   && apt-get autoclean -y \
   && rm -rf /var/lib/apt/lists/*

# Zeppelin
ENV ZEPPELIN_PORT 8080
ENV ZEPPELIN_HOME /usr/zeppelin
ENV ZEPPELIN_CONF_DIR $ZEPPELIN_HOME/conf
ENV ZEPPELIN_NOTEBOOK_DIR $ZEPPELIN_HOME/notebook
ENV ZEPPELIN_COMMIT v0.7.3
RUN echo '{ "allow_root": true }' > /root/.bowerrc
RUN set -ex \
 && buildDeps=' \
    git \
    bzip2 \
    npm \
 ' \
 && apt-get update && apt-get install -y --no-install-recommends $buildDeps \
 && curl -sL http://archive.apache.org/dist/maven/maven-3/3.5.0/binaries/apache-maven-3.5.0-bin.tar.gz \
   | gunzip \
   | tar x -C /tmp/ \
 && git clone https://github.com/apache/zeppelin.git /usr/src/zeppelin \
 && cd /usr/src/zeppelin \
 && git checkout -q $ZEPPELIN_COMMIT \
 && dev/change_scala_version.sh "2.11" \
 && MAVEN_OPTS="-Xmx2g -XX:MaxPermSize=1024m" /tmp/apache-maven-3.5.0/bin/mvn --batch-mode package -DskipTests -Pscala-2.11 -Pbuild-distr \
  -pl 'zeppelin-interpreter,zeppelin-zengine,zeppelin-display,spark-dependencies,spark,sparkr,r,markdown,angular,shell,hbase,postgresql,jdbc,python,elasticsearch,zeppelin-web,zeppelin-server,zeppelin-distribution' \
 && tar xvf /usr/src/zeppelin/zeppelin-distribution/target/zeppelin*.tar.gz -C /usr/ \
 && mv /usr/zeppelin* $ZEPPELIN_HOME \
 && mkdir -p $ZEPPELIN_HOME/logs \
 && mkdir -p $ZEPPELIN_HOME/run \
 && apt-get purge -y --auto-remove $buildDeps \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /usr/src/zeppelin \
 && rm -rf /root/.m2 \
 && rm -rf /root/.npm \
 && rm -rf /root/.cache/bower \
 && rm -rf /tmp/*

RUN ln -s /usr/bin/pip3 /usr/bin/pip \
 && ln -s /usr/bin/python3 /usr/bin/python

ADD about.json $ZEPPELIN_NOTEBOOK_DIR/2BTRWA9EV/note.json
WORKDIR $ZEPPELIN_HOME
CMD ["bin/zeppelin.sh"]
