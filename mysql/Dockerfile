FROM maven:3.6

ADD pom.xml /

USER root

# Download the JAR for the driver
RUN MYSQL_VERSION=`mvn -f /pom.xml org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=version.mysql -q -DforceStdout` && \
      echo "=> Downloading MySQL driver: ${MYSQL_VERSION}" && \
      curl --location --output /mysql-connector-java.jar --url http://search.maven.org/remotecontent?filepath=mysql/mysql-connector-java/${MYSQL_VERSION}/mysql-connector-java-${MYSQL_VERSION}.jar

FROM noverant/wildfly:latest

USER jboss

ENV JBOSS_CLI $JBOSS_HOME/bin/jboss-cli.sh
ENV JBOSS_MODE standalone
ENV DEPLOYMENT_DIR $JBOSS_HOME/$JBOSS_MODE/deployments/
ENV JBOSS_CONFIG standalone-full-ha.xml

COPY --from=0 --chown=jboss:jboss /mysql-connector-java.jar /tmp/

# Configure driver and add datasource
RUN echo "=> Starting WildFly server" && \
      sh -c '$JBOSS_HOME/bin/$JBOSS_MODE.sh -c $JBOSS_CONFIG --admin-only &' && \
    echo "=> Waiting for the server to boot" && \
      sh -c 'until `$JBOSS_CLI -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do echo `$JBOSS_CLI -c ":read-attribute(name=server-state)" 2> /dev/null`; sleep 1; done' && \
    echo "=> Adding MySQL module" && \
      $JBOSS_CLI --connect --command="module add \
        --name=org.mysql \
        --resources=/tmp/mysql-connector-java.jar \
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
      rm -rf /opt/jboss/wildfly/$JBOSS_MODE/{data,log,tmp} && \
      rm -f /tmp/*.jar