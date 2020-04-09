#!/bin/bash

WILDFLY_RELEASE=19.0.0

docker build . -t noverant/wildfly:latest -t noverant/wildfly:$WILDFLY_RELEASE
docker push noverant/wildfly:latest
docker push noverant/wildfly:$WILDFLY_RELEASE

docker build mariadb/ -t noverant/wildfly:latest-mariadb -t noverant/wildfly:$WILDFLY_RELEASE-mariadb
docker push noverant/wildfly:latest-mariadb
docker push noverant/wildfly:$WILDFLY_RELEASE-mariadb

docker build mysql/ -t noverant/wildfly:latest-mysql -t noverant/wildfly:$WILDFLY_RELEASE-mysql
docker push noverant/wildfly:latest-mysql
docker push noverant/wildfly:$WILDFLY_RELEASE-mysql
