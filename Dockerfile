FROM debian:buster-slim

ARG version=5.0.1

WORKDIR /tmp/build

# download SOPE sources
ADD https://github.com/inverse-inc/sope/archive/SOPE-${version}.tar.gz /tmp/src/sope/sope.tar.gz

# download SOGo sources
ADD https://github.com/inverse-inc/sogo/archive/SOGo-${version}.tar.gz /tmp/src/SOGo/SOGo.tar.gz

# prepare & compile
RUN echo "untar SOPE sources" \
   && tar -xf /tmp/src/sope/sope.tar.gz && mkdir /tmp/SOPE && mv sope-SOPE-${version}/* /tmp/SOPE/. \
   && echo "untar SOGO sources"  \
   && tar -xf /tmp/src/SOGo/SOGo.tar.gz && mkdir /tmp/SOGo && mv sogo-SOGo-${version}/* /tmp/SOGo/. \ 
   && echo "install required packages" \
   && apt-get update  \
   && apt-get install -qy --no-install-recommends \
      gnustep-make \
      gnustep-base-common \
      libgnustep-base-dev \
      make \
      gobjc \
      libxml2-dev \
      libssl-dev \
      libldap2-dev \
      libmemcached-dev \
      libcurl4-openssl-dev \
      default-libmysqlclient-dev \
      libexpat1 \
      libexpat1-dev \
      libexpat-dev \
      libpopt-dev  \
      libc6-dev  \
      libwbxml2-0  \
      libsodium-dev \
      libzip-dev \
      liboath-dev \
      wget \
      tzdata \
   && wget https://packages.inverse.ca/SOGo/nightly/5/debian/pool/buster/w/wbxml2/libwbxml2-0_0.11.6-1_amd64.deb  \
   && wget https://packages.inverse.ca/SOGo/nightly/5/debian/pool/buster/w/wbxml2/libwbxml2-dev_0.11.6-1_amd64.deb  \
   && dpkg -i libwbxml2-0*.deb  \
   && dpkg -i libwbxml2-dev*.deb  \
   && echo "compiling SOPE" \
   && cd /tmp/SOPE  \
   && ./configure --with-gnustep --enable-debug --disable-strip  \
   && make  \
   && make install  \
   && echo "compiling SOGo" \
   && cd /tmp/SOGo  \
   && ./configure --enable-debug --disable-strip --enable-mfa  \
   && make  \
   && echo "compiling ActiveSync" \
   && make install  \
   && cd /tmp/SOGo/ActiveSync  \
   && make install  \
   && echo "register sogo library" \
   && echo "/usr/local/lib/sogo" > /etc/ld.so.conf.d/sogo.conf  \
   && ldconfig \
   && echo "create user sogo" \
   && groupadd --system sogo && useradd --system --gid sogo sogo \
   && echo "create directories and enforce permissions" \
   && install -o sogo -g sogo -m 755 -d /var/run/sogo  \
   && install -o sogo -g sogo -m 750 -d /var/spool/sogo  \
   && install -o sogo -g sogo -m 750 -d /var/log/sogo \
   && rm -fr /tmp/*
   
# add sogo.conf
ADD sogo.default.conf /etc/sogo/sogo.conf

VOLUME /usr/local/lib/GNUstep/SOGo/WebServerResources

EXPOSE 20000

USER sogo

# load env
RUN . /usr/share/GNUstep/Makefiles/GNUstep.sh

CMD [ "sogod", "-WONoDetach", "YES", "-WOPort", "20000", "-WOLogFile", "-", "-WOPidFile", "/tmp/sogo.pid"]