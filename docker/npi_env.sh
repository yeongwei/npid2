# Sample template environment file for Docker, source this
# in the user profile that start the Docker service.

export HOSTNAME=$(hostname)
export HADOOP_NAMENODE_URL=hdfs://npi-nn-spark-hadoop:9000/
export ZOOKEEP_URL=npi-zk:2181
export NPI_STORAGE_HOST=npi-storage
export NPI_WORK_PATH=/data/work
# export NPI_CONF_PATH=/data/npi-conf    # optional if overriding NPI default /opt/npi/conf
