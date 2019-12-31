FROM adoptopenjdk/openjdk11-openj9:alpine-jre
# this image already contains glibc

WORKDIR /tmp

ARG UID=1000
ARG GID=1000
ENV JIRA_USER=jira
ENV JIRA_GROUP=jira
ENV CONTAINER_UID=$UID
ENV CONTAINER_GID=$GID
ENV JIRA_CONTEXT_PATH=ROOT
ENV JIRA_HOME=/var/atlassian/jira
ENV JIRA_INSTALL=/opt/jira
ENV JIRA_SCRIPTS=/usr/local/share/atlassian
ENV JRE_HOME=$JAVA_HOME
# Fix for this issue - https://jira.atlassian.com/browse/JRASERVER-46152
ENV _RUNJAVA=java
ENV JIRA_LIB=$JIRA_INSTALL/lib
ENV MYSQL_DRIVER_VERSION=2.4.2
ENV MYSQL_FILE=mariadb-java-client-$MYSQL_DRIVER_VERSION.jar
ENV MYSQL_DOWNLOAD_URL=https://downloads.mariadb.com/Connectors/java/connector-java-$MYSQL_DRIVER_VERSION/$MYSQL_FILE
ENV POSTGRESQL_DRIVER_VERSION=42.2.9
ENV POSTGRESQL_FILE=postgresql-$POSTGRESQL_DRIVER_VERSION.jar
ENV POSTGRESQL_DOWNLOAD_URL=https://jdbc.postgresql.org/download/$POSTGRESQL_FILE
ENV LE_DOWNLOAD_URL=https://letsencrypt.org/certs/
ENV LE_CROSS_3=lets-encrypt-x3-cross-signed.der
ENV KEYSTORE=$JRE_HOME/lib/security/cacerts
ENV JIRA_DOWNLOAD_URL=https://www.atlassian.com/software/jira/downloads/binary/
ENV SSLPOKE_URL=https://confluence.atlassian.com/kb/files/779355358/779355357/1/1441897666313/SSLPoke.class

# Version
ARG JIRA_VERSION=8.6.0
ARG JIRA_PRODUCT=jira-software

# Language
ARG LANG_LANGUAGE=en
ARG LANG_COUNTRY=US

COPY bin $JIRA_SCRIPTS

RUN apk add --update --no-cache \
      bash \
      su-exec \
      gzip \
      nano \
      tini \
      curl \
      xmlstarlet \
      fontconfig \
      msttcorefonts-installer \
      ttf-dejavu \
      ghostscript \
      graphviz \
      motif && \
      update-ms-fonts && \
      fc-cache -f && \
    mkdir -p \
      $JIRA_HOME \
      $JIRA_INSTALL \
      $JIRA_LIB && \
    addgroup -g \
      $CONTAINER_GID \
      $JIRA_GROUP && \
# Let's Encrypt \
# Adding Let's Encrypt CA to truststore \
# Only adding X3 as X4 will only be used as backup. If that happensy
# you can just rebuild the image \
    curl -LO $LE_DOWNLOAD_URL/$LE_CROSS_3 && \
    keytool -trustcacerts -keystore $KEYSTORE -storepass changeit -noprompt \
      -importcert -alias letsencryptauthorityx3 -file $LE_CROSS_3 && \
    curl -L $JIRA_DOWNLOAD_URL/atlassian-$JIRA_PRODUCT-$JIRA_VERSION.tar.gz | \
    tar xz -C $JIRA_INSTALL --strip 1 && \
    rm -rf $JIRA_INSTALL/jre && \
    ln -s $JAVA_HOME $JIRA_INSTALL/jre && \
# Add user must come after installer to avoid this: \
# https://confluence.atlassian.com/jirakb/how-to-set-the-user-jira-to-run-in-linux-433390559.html \
    adduser -u $CONTAINER_UID \
      -G $JIRA_GROUP \
      -h /home/$JIRA_USER \
      -s /bin/bash \
      -S $JIRA_USER && \
# Install Atlassian SSL tool - mainly to be able to create application links \
# with other Atlassian tools, which run LE SSL certificates \
    curl -Lo /home/$JIRA_USER/SSLPoke.class $SSLPOKE_URL && \
# Set permissions \
    chown -R $JIRA_USER:$JIRA_GROUP \
             $JIRA_HOME \
             $JIRA_INSTALL \
             $JIRA_SCRIPTS \
             /home/$JIRA_USER && \
# Install database drivers \
    rm -f $JIRA_LIB/mysql-connector-java*.jar && \
    curl -Lo $JIRA_LIB/$MYSQL_FILE $MYSQL_DOWNLOAD_URL && \
    rm -f $JIRA_LIB/postgresql-*.jar && \
    curl -Lo $JIRA_LIB/$POSTGRESQL_FILE $POSTGRESQL_DOWNLOAD_URL && \
# Remove build packages \
    apk del --no-cache msttcorefonts-installer && \
# Clean caches and tmps \
    rm -rf /var/cache/apk/* /tmp/* /var/log/*

USER $JIRA_USER
WORKDIR $JIRA_HOME
VOLUME ["$JIRA_HOME"]
EXPOSE 8080
ENTRYPOINT ["/sbin/tini","--","/usr/local/share/atlassian/docker-entrypoint.sh"]
CMD ["jira"]

# This is set by the build script.
# Keep this at the end of the Dockerfile to preserve the build cache
ARG BUILD_DATE

# Image Metadata
LABEL maintainer="Jonathan Hult <teamatldocker@JonathanHult.com>"                                  \
    org.opencontainers.image.authors="Jonathan Hult <teamatldocker@JonathanHult.com>"              \
    org.opencontainers.image.url="https://hub.docker.com/r/teamatldocker/jira/"                    \
    org.opencontainers.image.title=$JIRA_PRODUCT                                                   \
    org.opencontainers.image.description="$JIRA_PRODUCT $JIRA_VERSION running on Alpine Linux"     \
    org.opencontainers.image.source="https://github.com/teamatldocker/jira/"                       \
    org.opencontainers.image.created=$BUILD_DATE                                                   \
    org.opencontainers.image.version=$JIRA_VERSION
