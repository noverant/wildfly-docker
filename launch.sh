#!/bin/sh

export CONFIG_FILE="${CONFIG_FILE:-standalone.xml}"

export BIND_OPTS="${BIND_OPTS:--b 0.0.0.0}"

export PORT_OFFSET="${PORT_OFFSET:-0}"

export JAVA_OPTS="-server -XX:InitialRAMPercentage=${INIT_RAM_PCT:-50.0} -XX:MaxRAMPercentage=${MAX_RAM_PCT:-70.0} -XX:MinRAMPercentage=${MIN_RAM_PCT:-50.0} -Djava.net.preferIPv4Stack=true -Djboss.modules.system.pkgs=org.jboss.byteman -Djava.awt.headless=true --add-exports=java.base/sun.nio.ch=ALL-UNNAMED --add-exports=jdk.unsupported/sun.misc=ALL-UNNAMED --add-exports=jdk.unsupported/sun.reflect=ALL-UNNAMED -Djdk.tls.client.protocols=TLSv1.2"

export JAVA_OPTS="$JAVA_OPTS $EXTRA_JAVA_OPTS"

/bin/sh /opt/jboss/wildfly/bin/standalone.sh -c $CONFIG_FILE $BIND_OPTS -Djboss.socket.binding.port-offset=$PORT_OFFSET