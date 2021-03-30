FROM maven:3.6

ADD pom.xml /

USER root

# Download the JAR for the driver
RUN MARIADB_VERSION=`mvn -f /pom.xml help:evaluate -Dexpression=version.mariadb -q -DforceStdout` && \
      echo "=> Downloading MariaDB driver: $MARIADB_VERSION" && \
      curl --location --output /mariadb-java-client.jar --url http://search.maven.org/remotecontent?filepath=org/mariadb/jdbc/mariadb-java-client/${MARIADB_VERSION}/mariadb-java-client-${MARIADB_VERSION}.jar

FROM noverant/wildfly:latest

USER jboss

ENV JBOSS_CLI /bin/bash $JBOSS_HOME/bin/jboss-cli.sh
ENV JBOSS_MODE standalone
ENV DEPLOYMENT_DIR $JBOSS_HOME/$JBOSS_MODE/deployments/
ENV JBOSS_CONFIG standalone-full-ha.xml

COPY --from=0 --chown=jboss:jboss /mariadb-java-client.jar /tmp/

# Configure driver and add datasource
RUN echo "=> Starting WildFly server" && \
      sh -c '$JBOSS_HOME/bin/$JBOSS_MODE.sh -c $JBOSS_CONFIG --admin-only &' && \
    echo "=> Waiting for the server to boot" && \
      sh -c 'until `$JBOSS_CLI -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do echo `$JBOSS_CLI -c ":read-attribute(name=server-state)"`; sleep 1; done' && \
    echo "=> Adding MariaDB module" && \
      $JBOSS_CLI --connect --command="module add \
        --name=org.mariadb \
        --resources=/tmp/mariadb-java-client.jar \
        --dependencies=javax.api,javax.transaction.api" && \
    echo "=> Adding MariaDB driver" && \
      $JBOSS_CLI --connect --command="/subsystem= \
        datasources/jdbc-driver=mariadb:add( \
          driver-name="mariadb", \
          driver-module-name="org.mariadb", \
          driver-class-name=org.mariadb.jdbc.Driver, \
          driver-xa-datasource-class-name=org.mariadb.jdbc.MySQLDataSource \
        )" && \
    echo "=> Shutting down WildFly and Cleaning up" && \
      $JBOSS_CLI --connect --command=":shutdown" && \
      rm -rf $JBOSS_HOME/$JBOSS_MODE/configuration/*_xml_history/ $JBOSS_HOME/$JBOSS_MODE/log/* && \
      rm -rf /opt/jboss/wildfly/$JBOSS_MODE/{data,log,tmp} && \
      rm -f /tmp/*.jar