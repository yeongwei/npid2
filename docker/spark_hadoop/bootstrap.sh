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

WAIT_PID=0
nn_service() {
	cmd=$1
	NAMENODES=$($HADOOP_PREFIX/bin/hdfs getconf -namenodes)
	
	echo "$cmd namenodes on [$NAMENODES]"
	
	"$HADOOP_PREFIX/sbin/hadoop-daemon.sh" \
	  --config "$HADOOP_CONF_DIR" \
	  --hostnames "$NAMENODES" \
	  --script "$HADOOP_PREFIX/bin/hdfs" $cmd namenode 
	  
	SECONDARY_NAMENODES=$($HADOOP_PREFIX/bin/hdfs getconf -secondarynamenodes 2>/dev/null)
	
	if [ -n "$SECONDARY_NAMENODES" ]; then
	  echo "$cmd secondary namenodes [$SECONDARY_NAMENODES]"
	
	  "$HADOOP_PREFIX/sbin/hadoop-daemon.sh" \
	      --config "$HADOOP_CONF_DIR" \
	      --hostnames "$SECONDARY_NAMENODES" \
	      --script "$HADOOP_PREFIX/bin/hdfs" $cmd secondarynamenode
	  if [ $WAIT_PID -eq 0 ];then
	  	WAIT_PID=$(cat /tmp/hadoop-*-secondarynamenode.pid |head -1)
	  fi
	fi
    
    if [ $WAIT_PID -eq 0 ];then
	  	WAIT_PID=$(cat /tmp/hadoop-*-namenode.pid |head -1)
	fi
	"$HADOOP_PREFIX"/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR $cmd resourcemanager	
}

dt_service() {
	cmd=$1
	echo "$cmd datanode"
	"$HADOOP_PREFIX/sbin/hadoop-daemon.sh" \
	    --config "$HADOOP_CONF_DIR" \
	    --script "$HADOOP_PREFIX/bin/hdfs" $cmd datanode
	echo "$cmd YARN nodemanager"
	"$HADOOP_PREFIX"/sbin/yarn-daemon.sh --config $HADOOP_CONF_DIR $cmd nodemanager	
	if [ $WAIT_PID -eq 0 ];then
		WAIT_PID=$(cat /tmp/hadoop-*-datanode.pid |head -1)
	fi
}

echo "Starting Hadoop services"
sleep $START_DELAY

term_handler() {
	echo "Signal received, stopping process"
	dt_service stop
	if [ ! -z $NAMENODE ];then #fix this to check for true/false
		nn_service stop
	fi
}

copy_spark_jar_and_conf() {
	echo "Waiting for recovering from safemode"
	$NPI_HOME/services/hadoop/bin/hdfs dfsadmin -safemode wait

	echo "Creating /work/hadoop-conf folder"
	$NPI_HOME/services/hadoop/bin/hdfs dfs -mkdir -p /work/hadoop-conf
	echo "Copying hadoop config files to hdfs"
	$NPI_HOME/services/hadoop/bin/hdfs dfs -copyFromLocal -f $NPI_HOME/services/hadoop/etc/hadoop/core-site.xml /work/hadoop-conf/core-site.xml
	$NPI_HOME/services/hadoop/bin/hdfs dfs -copyFromLocal -f $NPI_HOME/services/hadoop/etc/hadoop/hdfs-site.xml /work/hadoop-conf/hdfs-site.xml
	$NPI_HOME/services/hadoop/bin/hdfs dfs -copyFromLocal -f $NPI_HOME/services/hadoop/etc/hadoop/yarn-site.xml /work/hadoop-conf/yarn-site.xml
	$NPI_HOME/services/hadoop/bin/hdfs dfs -copyFromLocal -f $NPI_HOME/services/hadoop/etc/hadoop/spark-defaults.conf /work/hadoop-conf/spark-defaults.conf

	echo "Creating /work/spark-lib folder"
	$NPI_HOME/services/hadoop/bin/hdfs dfs -mkdir -p /work/spark-lib
	echo "Copying spark assembly jar to hdfs"
	$NPI_HOME/services/hadoop/bin/hdfs dfs -copyFromLocal -f $NPI_HOME/services/spark/lib/spark-assembly-*.jar /work/spark-lib/spark-assembly-hadoop.jar
}

trap "term_handler;exit" SIGTERM SIGINT

if [ "$USER_CONFIG" != "true" ];then
	if [ ! -z $NAMENODE ] && [ "$NAMENODE" == "true" ];then
	  export NAMENODE_HOST=${NAMENODE_HOST:-"hdfs://$(hostname):9000/"}
	  (cd $NPI_HOME && ./bin/initHadoopNamenode.sh $NAMENODE_HOST)
	elif [ ! -z $NAMENODE_HOST ];then
	  (cd $NPI_HOME && ./bin/initHadoopNamenode.sh $NAMENODE_HOST)	
	fi
fi

source $NPI_HOME/services/hadoop/etc/hadoop/hadoop-env.sh
if [ -f $NPI_HOME/services/spark/conf/spark-env.sh ];then
	source $NPI_HOME/services/spark/conf/spark-env.sh
fi

export PATH=$PATH:$HADOOP_HOME/bin

if [ ! -z $NAMENODE ] && [ "$NAMENODE" == "true" ];then
	if [ ! -d $NPI_HOME/work/dfs ];then
		echo "Starting as NAMENODE and no HDFS found, formating new HDFS"
		$NPI_HOME/services/hadoop/bin/hdfs namenode -format
	fi
	
	nn_service start
	copy_spark_jar_and_conf
fi

dt_service start

#cd $NPI_HOME/services/hadoop && ./sbin/start-dfs.sh
#cd $NPI_HOME/services/hadoop && ./sbin/start-yarn.sh

tail -f $NPI_HOME/services/hadoop/logs/hadoop-*.log & 

while [ $(ps $WAIT_PID 2&> /dev/null;echo $?) -eq 0 ];do sleep 1;done
