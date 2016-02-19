# Sample template environment file for Docker, source this
# in the user profile that start the Docker service.

# Defaults to standalone environment file ???
export HOSTNAME=$(hostname)
export HADOOP_NAMENODE_URL=hdfs://${HOSTNAME}:9000/
export ZOOKEEP_URL=${HOSTNAME}:2181
export NPI_STORAGE_HOST=${HOSTNAME}
export NPI_WORK_PATH=/data/work
# export NPI_CONF_PATH=/data/npi-conf    # optional if overriding NPI default /opt/npi/conf

export NAMENODE=true
export USER_CONFIG=false

export HADOOP_PREFIX=${SERVICES_DIR}/hadoop
export STORAGE_URL=$HADOOP_NAMENODE_URL
export ZK_URL=$ZOOKEEP_URL

export JDBC_SERVICE=${JDBC_SERVICE:-"`hostname`:8091"}
export HADOOP_RM_PORT=${HADOOP_RM_PORT:-8088}
export HADOOP_PID_DIR=${VAR_DIR:-"/tmp"}
export YARN_PID_DIR=${VAR_DIR:-"/tmp"}
