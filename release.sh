#!/bin/bash

WILDFLY_RELEASE=23.0.2
MARIADB_VERSION=`mvn -f mariadb/pom.xml help:evaluate -Dexpression=version.mariadb -q -DforceStdout`
MYSQL_VERSION=`mvn -f mysql/pom.xml help:evaluate -Dexpression=version.mysql -q -DforceStdout`

echo "=> MariaDB driver: ${MARIADB_VERSION}"
echo "=> MySQL driver: ${MYSQL_VERSION}"

docker build . -t noverant/wildfly:latest -t noverant/wildfly:$WILDFLY_RELEASE
docker push noverant/wildfly:latest
docker push noverant/wildfly:$WILDFLY_RELEASE

docker build mariadb/ -t noverant/wildfly:latest-mariadb -t noverant/wildfly:$WILDFLY_RELEASE-mariadb -t noverant/wildfly:$WILDFLY_RELEASE-mariadb-$MARIADB_VERSION
docker push noverant/wildfly:latest-mariadb
docker push noverant/wildfly:$WILDFLY_RELEASE-mariadb
docker push noverant/wildfly:$WILDFLY_RELEASE-mariadb-$MARIADB_VERSION

docker build mysql/ -t noverant/wildfly:latest-mysql -t noverant/wildfly:$WILDFLY_RELEASE-mysql -t noverant/wildfly:$WILDFLY_RELEASE-mysql-$MYSQL_VERSION
docker push noverant/wildfly:latest-mysql
docker push noverant/wildfly:$WILDFLY_RELEASE-mysql
docker push noverant/wildfly:$WILDFLY_RELEASE-mysql-$MYSQL_VERSION
