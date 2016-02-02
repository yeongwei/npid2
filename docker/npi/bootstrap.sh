#!/bin/sh
#/*--------------------------------------------------------------------------
# * Licensed Materials - Property of IBM
# * 5724-P55, 5724-P57, 5724-P58, 5724-P59
# * Copyright IBM Corporation 2007. All Rights Reserved.
# * US Government Users Restricted Rights- Use, duplication or disclosure
# * restricted by GSA ADP Schedule Contract with IBM Corp.
# *--------------------------------------------------------------------------*/

export NPI_HOME=${NPI_HOME:-"/opt/npi"}
export PROG_NAME=npi
export START_DELAY=${START_DELAY:-3}

WEB_PORT=${WEB_PORT:-8081}
WEB_SEC_PORT=${WEB_SEC_PORT:-9443}
JMX_PORT=${JMX_PORT:-9010}

if [ ! -z $STORAGE_URL ];then
  JVM_OPT="${JVM_OPT} -Dstorage.uri=${STORAGE_URL}"
fi

if [ ! -z $ZK_URL ];then
  JVM_OPT="${JVM_OPT} -Dakka.cluster.seed.zookeeper.url=${ZK_URL} -Dkafka-snapshot-store.zookeeper.connect=${ZK_URL}/${ZKPREFIX}kafka -Dkafka-journal.zookeeper.connect=${ZK_URL}/${ZKPREFIX}kafka"
fi

if [ ! -z ${COMPONENT} ];then
   JVM_OPT="${JVM_OPT} -Dnpi.component=${COMPONENT}"
fi

if [ ! -z ${JDBC_SERVICE} ];then
	JVM_OPT="${JVM_OPT} -Dstorage.jdbc-service=${JDBC_SERVICE}"
fi

export JVM_OPT

term_handler() {
    RUNNING_PID=$1
    trycount=0
	echo "Signal received, stopping process"
	while [ "${RUNNING_PID}" != "" ] && [ $trycount -le 10 ]; do
      echo "GYMPB0111I: Stopping $PROG_NAME (PID: $RUNNING_PID)"
      kill -HUP $RUNNING_PID
      trycount=$(( $trycount + 1 ))
      sleep 15
      RUNNING_PID=$(ps -eaf | grep -v grep | grep Dprog.name=${PROG_NAME} | awk '{print $2}' | xargs)
    done
}

sleep $START_DELAY
$NPI_HOME/bin/npi > /dev/null 2> $NPI_HOME/log/npid.log &
WAIT_PID=${!}

trap "term_handler $WAIT_PID;exit" SIGTERM SIGINT

#Enable log file creation
touch $NPI_HOME/log/npi.log
tail -f $NPI_HOME/log/npi.log & wait $WAIT_PID