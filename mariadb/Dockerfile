FROM maven:3.6-alpine as mvn

ADD pom.xml /

USER root

RUN mkdir /tmp/deps && \
    mvn -f /pom.xml dependency:copy-dependencies -DoutputDirectory=/tmp/deps/ && \
    cd /tmp/deps/ && \
    mv mariadb-java-client* mariadb-java-client.jar && \
    mv aws-java-sdk-core* aws-java-sdk-core.jar && \
    mv aws-java-sdk-rds* aws-java-sdk-rds.jar && \
    mv commons-logging* commons-logging.jar && \
    mv httpclient* httpclient.jar && \
    mv httpcore* httpcore.jar


FROM noverant/wildfly:latest

USER jboss

ENV JBOSS_CLI /bin/bash $JBOSS_HOME/bin/jboss-cli.sh
ENV JBOSS_MODE standalone
ENV DEPLOYMENT_DIR $JBOSS_HOME/$JBOSS_MODE/deployments/
ENV JBOSS_CONFIG standalone-full-ha.xml

COPY --from=0 --chown=jboss:jboss /tmp/deps/ /tmp/deps/

# Configure driver and add datasource
RUN echo "=> Starting WildFly server" && \
      sh -c '$JBOSS_HOME/bin/$JBOSS_MODE.sh -c $JBOSS_CONFIG --admin-only &' && \
    echo "=> Waiting for the server to boot" && \
      sh -c 'until `$JBOSS_CLI -c ":read-attribute(name=server-state)" 2> /dev/null | grep -q running`; do echo `$JBOSS_CLI -c ":read-attribute(name=server-state)"`; sleep 1; done' && \
    echo "=> Adding AWS RDS SDK" && \
      $JBOSS_CLI --connect --command="module add \
        --name=com.amazonaws \
        --resource-delimiter=, \
        --resources=/tmp/deps/aws-java-sdk-core.jar,/tmp/deps/aws-java-sdk-rds.jar,/tmp/deps/commons-logging.jar,/tmp/deps/httpclient.jar,/tmp/deps/httpcore.jar \
        --dependencies=javax.api,javax.xml.stream.api,javax.xml.bind.api,com.fasterxml.jackson.core.jackson-core,com.fasterxml.jackson.core.jackson-databind,com.fasterxml.jackson.core.jackson-annotations,org.joda.time" && \
    echo "=> Adding MariaDB module" && \
      $JBOSS_CLI --connect --command="module add \
        --name=org.mariadb \
        --resources=/tmp/deps/mariadb-java-client.jar \
        --dependencies=javax.api,javax.transaction.api,com.amazonaws" && \
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
      rm -rf /tmp/deps/