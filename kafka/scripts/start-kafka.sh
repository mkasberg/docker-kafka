#!/bin/sh

# Optional ENV variables:
#
# * ADVERTISED_HOST (DEPRECATED): the external ip for the container, e.g. `docker-machine ip \`docker-machine active\``
# * ADVERTISED_PORT (DEPRECATED): the external port for Kafka, e.g. 9092
#
# * KAFKA_LISTENERS: The host/ip(s) Kafka binds to listen on, e.g. "INTERNAL://kafka:9092,EXTERNAL://kafka:9094"
# * KAFKA_ADVERTISED_LISTENERS: Listener metadata which can be passed back to clients, e.g. "INTERNAL://kafka:9092,EXTERNAL://localhost:9094"
# * KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: Defines key/value pairs for the security protocol to use, e.g. "INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT"
# * KAFKA_INTER_BROKER_LISTENER_NAME: Name of listener used for communication between brokers, e.g. "INTERNAL"
#
# * ZK_CHROOT: the zookeeper chroot that's used by Kafka (without / prefix), e.g. "kafka"
# * LOG_RETENTION_HOURS: the minimum age of a log file in hours to be eligible for deletion (default is 168, for 1 week)
# * LOG_RETENTION_BYTES: configure the size at which segments are pruned from the log, (default is 1073741824, for 1GB)
# * NUM_PARTITIONS: configure the default number of log partitions per topic

# Add new line before adding any config into server.properties.
# This prevents a property being added onto the same line as 
# another property
echo "" >> $KAFKA_HOME/config/server.properties

# Configure advertised host/port if we run in helios
if [ ! -z "$HELIOS_PORT_kafka" ]; then
    ADVERTISED_HOST=`echo $HELIOS_PORT_kafka | cut -d':' -f 1 | xargs -n 1 dig +short | tail -n 1`
    ADVERTISED_PORT=`echo $HELIOS_PORT_kafka | cut -d':' -f 2`
fi

# Set the external host and port
#
# NOTE: advertiser.host.name and advertised.port are deprecated in Kafka - they remain
# here for backwards compatibility. Listeners should be used instead.
# More info: https://kafka.apache.org/10/documentation.html#brokerconfigs
if [ ! -z "$ADVERTISED_HOST" ]; then
    echo "advertised host: $ADVERTISED_HOST"
    echo "advertised.host.name=$ADVERTISED_HOST" >> $KAFKA_HOME/config/server.properties
fi
if [ ! -z "$ADVERTISED_PORT" ]; then
    echo "advertised port: $ADVERTISED_PORT"
    echo "advertised.port=$ADVERTISED_PORT" >> $KAFKA_HOME/config/server.properties
fi

# Configure listeners and security protocol
if [ ! -z "$KAFKA_LISTENERS" ]; then
    echo "kafka listeners: $KAFKA_LISTENERS"
    echo "listeners=$KAFKA_LISTENERS" >> $KAFKA_HOME/config/server.properties
fi
if [ ! -z "$KAFKA_ADVERTISED_LISTENERS" ]; then
    echo "kafka advertised listeners: $KAFKA_ADVERTISED_LISTENERS"
    echo "advertised.listeners=$KAFKA_ADVERTISED_LISTENERS" >> $KAFKA_HOME/config/server.properties
fi
if [ ! -z "$KAFKA_LISTENER_SECURITY_PROTOCOL_MAP" ]; then
    echo "kafka listener security protocol map: $KAFKA_LISTENER_SECURITY_PROTOCOL_MAP"
    echo "listener.security.protocol.map=$KAFKA_LISTENER_SECURITY_PROTOCOL_MAP" >> $KAFKA_HOME/config/server.properties
fi
if [ ! -z "$KAFKA_INTER_BROKER_LISTENER_NAME" ]; then
    echo "kafka inter broker listener name: $KAFKA_INTER_BROKER_LISTENER_NAME"
    echo "inter.broker.listener.name=$KAFKA_INTER_BROKER_LISTENER_NAME" >> $KAFKA_HOME/config/server.properties
fi

# Set the zookeeper chroot
if [ ! -z "$ZK_CHROOT" ]; then
    # wait for zookeeper to start up
    until /usr/share/zookeeper/bin/zkServer.sh status; do
      sleep 0.1
    done

    # create the chroot node
    echo "create /$ZK_CHROOT \"\"" | /usr/share/zookeeper/bin/zkCli.sh || {
        echo "can't create chroot in zookeeper, exit"
        exit 1
    }

    # configure kafka
    sed -r -i "s/(zookeeper.connect)=(.*)/\1=localhost:2181\/$ZK_CHROOT/g" $KAFKA_HOME/config/server.properties
fi

# Allow specification of log retention policies
if [ ! -z "$LOG_RETENTION_HOURS" ]; then
    echo "log retention hours: $LOG_RETENTION_HOURS"
    sed -r -i "s/(log.retention.hours)=(.*)/\1=$LOG_RETENTION_HOURS/g" $KAFKA_HOME/config/server.properties
fi
if [ ! -z "$LOG_RETENTION_BYTES" ]; then
    echo "log retention bytes: $LOG_RETENTION_BYTES"
    sed -r -i "s/#(log.retention.bytes)=(.*)/\1=$LOG_RETENTION_BYTES/g" $KAFKA_HOME/config/server.properties
fi

# Configure the default number of log partitions per topic
if [ ! -z "$NUM_PARTITIONS" ]; then
    echo "default number of partition: $NUM_PARTITIONS"
    sed -r -i "s/(num.partitions)=(.*)/\1=$NUM_PARTITIONS/g" $KAFKA_HOME/config/server.properties
fi

# Enable/disable auto creation of topics
if [ ! -z "$AUTO_CREATE_TOPICS" ]; then
    echo "auto.create.topics.enable: $AUTO_CREATE_TOPICS"
    echo "auto.create.topics.enable=$AUTO_CREATE_TOPICS" >> $KAFKA_HOME/config/server.properties
fi

# Run Kafka
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/server.properties
