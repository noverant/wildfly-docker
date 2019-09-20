FROM noverant/wildfly-docker:latest

USER root

RUN apk update && apk add maven && rm -rf /var/cache/apk/*

ADD pom.xml /

USER jboss

ENV JBOSS_CLI $JBOSS_HOME/bin/jboss-cli.sh
ENV JBOSS_MODE standalone
ENV DEPLOYMENT_DIR $JBOSS_HOME/$JBOSS_MODE/deployments/
ENV JBOSS_CONFIG standalone-full-ha.xml

# If we haven't specified a version, go ahead and grab the version from our pom.xml
RUN if [ -z "$MYSQL_VERSION" ]; then export MYSQL_VERSION=`mvn -f /pom.xml org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=version.mysql | grep -Ev '(\[|Downloaded|Downloading)'`; fi

# Download the JAR for the driver
RUN echo "=> Downloading MySQL driver" && \
      curl --location --output /tmp/mysql-connector-java-${MYSQL_VERSION}.jar --url http://search.maven.org/remotecontent?filepath=mysql/mysql-connector-java/${MYSQL_VERSION}/mysql-connector-java-${MYSQL_VERSION}.jar

# Configure driver and add datasource
RUN echo "=> Starting WildFly server" && \
      sh -c '$JBOSS_HOME/bin/$JBOSS_MODE.sh -c $JBOSS_CONFIG --admin-only &' && \
    echo "=> Waiting for the server to boot" && \
      sh -c 'until `$JBOSS_CLI -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do echo `$JBOSS_CLI -c ":read-attribute(name=server-state)" 2> /dev/null`; sleep 1; done' && \
    echo "=> Adding MySQL module" && \
      $JBOSS_CLI --connect --command="module add \
        --name=org.mysql \
        --resources=/tmp/mysql-connector-java-${MYSQL_VERSION}.jar \
        --dependencies=javax.api,javax.transaction.api" && \
    echo "=> Adding MySQL driver" && \
      $JBOSS_CLI --connect --command="/subsystem= \
        datasources/jdbc-driver=mysql:add( \
          driver-name=mysql, \
          driver-module-name=org.mysql, \
          driver-xa-datasource-class-name=org.mysql.jdbc.MySQLDataSource \
        )" && \
    echo "=> Shutting down WildFly and Cleaning up" && \
      $JBOSS_CLI --connect --command=":shutdown" && \
      rm -rf $JBOSS_HOME/$JBOSS_MODE/configuration/*_xml_history/ $JBOSS_HOME/$JBOSS_MODE/log/* && \
	    rm -f /tmp/*.jar && \
      rm -rf /opt/jboss/wildfly/$JBOSS_MODE/{data,log,tmp}

USER root

RUN apk update && apk del maven curl sed && rm -rf /var/cache/apk/*

USER jboss