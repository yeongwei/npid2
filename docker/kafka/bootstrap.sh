#!/bin/sh
#/*--------------------------------------------------------------------------
# * Licensed Materials - Property of IBM
# * 5724-P55, 5724-P57, 5724-P58, 5724-P59
# * Copyright IBM Corporation 2007. All Rights Reserved.
# * US Government Users Restricted Rights- Use, duplication or disclosure
# * restricted by GSA ADP Schedule Contract with IBM Corp.
# *--------------------------------------------------------------------------*/

export NPI_HOME=${NPI_HOME:-"/opt/npi"}
export START_DELAY=${START_DELAY:-3}

echo "Starting KAFKA services"

sleep $START_DELAY

term_handler() {
	echo "Signal received, stopping process"
	(cd $NPI_HOME/services/kafka && ./bin/kafka-server-stop.sh)
}

trap "term_handler;exit" SIGTERM SIGINT

if [ ! -z $ZK_CONNECT ];then
   (cat $NPI_HOME/services/conf/kafka/kafka-server.properties | \
       sed -e "s|^.*zookeeper.connect=.*|zookeeper.connect=$ZK_CONNECT|g") > \
           $NPI_HOME/services/conf/kafka/tmp.zk
   mv $NPI_HOME/services/conf/kafka/tmp.zk $NPI_HOME/services/conf/kafka/kafka-server.properties
fi

if [ ! -z $EXT_HOSTNAME ];then
   (cat $NPI_HOME/services/conf/kafka/kafka-server.properties | \
       sed -e "s|^.*advertised.host.name=.*|advertised.host.name=$EXT_HOSTNAME|g") > \
           $NPI_HOME/services/conf/kafka/tmp.host
   mv $NPI_HOME/services/conf/kafka/tmp.host $NPI_HOME/services/conf/kafka/kafka-server.properties

fi

if [ ! -z $EXT_PORT ];then
   (cat $NPI_HOME/services/conf/kafka/kafka-server.properties | \
       sed -e "s|^.*advertised.port=.*|advertised.port=$EXT_PORT|g") > \
           $NPI_HOME/services/conf/kafka/tmp.port
   mv $NPI_HOME/services/conf/kafka/tmp.port $NPI_HOME/services/conf/kafka/kafka-server.properties

fi

(cd $NPI_HOME/services/kafka && ./bin/kafka-server-start.sh $NPI_HOME/services/conf/kafka/kafka-server.properties) & wait ${!}
