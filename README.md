Kafka in Docker
===

This repository provides everything you need to run Kafka in Docker.

**Updated for Kafka 0.10.2.0.**

Why?
---
The main hurdle of running Kafka in Docker is that it depends on Zookeeper.
Compared to other Kafka docker images, this one runs both Zookeeper and Kafka
in the same container. This means:

* No dependency on an external Zookeeper host, or linking to another container.
* Zookeeper and Kafka are configured to work together out of the box.

Simple Run
---

Start the container:

```bash
docker run -p 2181:2181 -p 9092:9092 spotx/kafka:1.0.0
```

Write a test message to kafka:

```bash
docker exec -it <container_id> ./opt/kafka_2.11-1.0.0/bin/kafka-console-producer.sh --broker-list localhost:9092 --topic test
```

Read the test message:

```bash
docker exec -it <container_id> ./opt/kafka_2.11-1.0.0/bin/kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic test --from-beginning
```

Complex Run
---

In a more complex setup, internal and external listeners can be defined
to allow access from outside the container

1. Configure with Docker Compose file:

```
version: '3'
services:
  kafka:
    image: spotx/kafka:1.0.0
    ports:
    - "2181:2181"
    - "9092:9094"
    environment:
      KAFKA_LISTENERS: INTERNAL://kafka:9092,EXTERNAL://kafka:9094
      KAFKA_ADVERTISED_LISTENERS: INTERNAL://kafka:9092,EXTERNAL://localhost:9094
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: INTERNAL:PLAINTEXT,EXTERNAL:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: INTERNAL
```

2. Start service

```bash
docker-compose -f <compose_file>.yml up
```

Write a test message to kafka:

```bash
kafka-console-producer.sh --broker-list localhost:9092 --topic test
```

Read the test message:

```bash
kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic test --from-beginning
```

In the box
---
* **spotx/kafka**

  The docker image with both Kafka and Zookeeper. Built from the `kafka`
  directory.

Public Builds
---

https://hub.docker.com/r/spotx/kafka/

Build from Source
---

    docker build -t spotx/kafka kafka/

Todo
---

* Not particularily optimzed for startup time.
* Better docs

