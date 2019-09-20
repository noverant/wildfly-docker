FROM noverant/wildfly:latest

USER root

RUN apk update && apk add maven && rm -rf /var/cache/apk/*

ADD pom.xml /

USER jboss

ENV JBOSS_CLI $JBOSS_HOME/bin/jboss-cli.sh
ENV JBOSS_MODE standalone
ENV DEPLOYMENT_DIR $JBOSS_HOME/$JBOSS_MODE/deployments/
ENV JBOSS_CONFIG standalone-full-ha.xml

# If we haven't specified a version, go ahead and grab the version from our pom.xml
RUN if [ -z "$MARIADB_VERSION" ]; then export MARIADB_VERSION=`mvn -f /pom.xml org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=version.mariadb | grep -Ev '(\[|Downloaded|Downloading)'`; fi

# Download the JAR for the driver
RUN echo "=> Downloading MariaDB driver" && \
      curl --location --output /tmp/mariadb-java-client-${MARIADB_VERSION}.jar --url http://search.maven.org/remotecontent?filepath=org/mariadb/jdbc/mariadb-java-client/${MARIADB_VERSION}/mariadb-java-client-${MARIADB_VERSION}.jar

# Configure driver and add datasource
RUN echo "=> Starting WildFly server" && \
      sh -c '$JBOSS_HOME/bin/$JBOSS_MODE.sh -c $JBOSS_CONFIG --admin-only &' && \
    echo "=> Waiting for the server to boot" && \
      sh -c 'until `$JBOSS_CLI -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do echo `$JBOSS_CLI -c ":read-attribute(name=server-state)" 2> /dev/null`; sleep 1; done' && \
    echo "=> Adding MariaDB module" && \
      $JBOSS_CLI --connect --command="module add \
        --name=org.mariadb \
        --resources=/tmp/mariadb-java-client-${MARIADB_VERSION}.jar \
        --dependencies=javax.api,javax.transaction.api" && \
    echo "=> Adding MariaDB driver" && \
      $JBOSS_CLI --connect --command="/subsystem= \
        datasources/jdbc-driver=mariadb:add( \
          driver-name=mariadb, \
          driver-module-name=org.mariadb, \
          driver-xa-datasource-class-name=org.mariadb.jdbc.MySQLDataSource \
        )" && \
    echo "=> Shutting down WildFly and Cleaning up" && \
      $JBOSS_CLI --connect --command=":shutdown" && \
      rm -rf $JBOSS_HOME/$JBOSS_MODE/configuration/*_xml_history/ $JBOSS_HOME/$JBOSS_MODE/log/* && \
	  rm -f /tmp/*.jar && \
      rm -rf /opt/jboss/wildfly/$JBOSS_MODE/{data,log,tmp}

USER root

RUN apk update && apk del maven curl sed && rm -rf /var/cache/apk/*

USER jboss