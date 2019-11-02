ARG WILDFLY_VERSION=18.0.0.Final
ARG JBOSS_HOME=/opt/jboss/wildfly

FROM appropriate/curl
MAINTAINER Jonathan Putney <jputney@noverant.com>

ARG WILDFLY_VERSION
ARG JBOSS_HOME

ENV JBOSS_HOME=${JBOSS_HOME}
ENV WILDFLY_VERSION=${WILDFLY_VERSION}
ENV WILDFLY_SHA1 2d4778b14fda6257458a26943ea82988e3ae6a66

USER root

RUN cd $HOME \
    && addgroup -S jboss -g 1000 && adduser -u 1000 -S -G jboss -h /opt/jboss -s /sbin/nologin jboss \
    && curl -O https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
    && sha1sum wildfly-$WILDFLY_VERSION.tar.gz | grep $WILDFLY_SHA1 \
    && tar xf wildfly-$WILDFLY_VERSION.tar.gz

FROM openjdk:13-alpine

ARG WILDFLY_VERSION
ARG JBOSS_HOME

# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION=${WILDFLY_VERSION}
ENV JBOSS_HOME=${JBOSS_HOME}

USER root

# Create a user and group used to launch processes
# The user ID 1000 is the default for the first "regular" user on Fedora/RHEL,
# so there is a high chance that this ID will be equal to the current user
# making it easier to use volumes (no permission issues)
RUN addgroup -S jboss -g 1000 && adduser -u 1000 -S -G jboss -h /opt/jboss -s /sbin/nologin jboss

# Add the WildFly distribution to $JBOSS_HOME
COPY --from=0 --chown=jboss:jboss /root/wildfly-$WILDFLY_VERSION $JBOSS_HOME

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

# Expose the ports we're interested in
EXPOSE 8080

# Copy our launch script that 
ADD launch.sh /
RUN chmod +x /launch.sh

USER jboss

# Run WildFly when the container boots
ENTRYPOINT ["/launch.sh"]