# Sample template environment file for Docker, source this
# in the user profile that start the Docker service.

# Defaults to standalone environment file ???
export HOSTNAME=$(hostname)
export HADOOP_NAMENODE_URL=hdfs://${HOSTNAME}:9000/
export ZOOKEEP_URL=${HOSTNAME}:2181
export NPI_STORAGE_HOST=${HOSTNAME}
export NPI_WORK_PATH=/data/work
# export NPI_CONF_PATH=/data/npi-conf    # optional if overriding NPI default /opt/npi/conf
