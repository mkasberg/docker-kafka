Kafka in Docker
===

This repository provides everything you need to run Kafka in Docker.

**Updated for Kafka 0.10.1.0.**

Why?
---
The main hurdle of running Kafka in Docker is that it depends on Zookeeper.
Compared to other Kafka docker images, this one runs both Zookeeper and Kafka
in the same container. This means:

* No dependency on an external Zookeeper host, or linking to another container.
* Zookeeper and Kafka are configured to work together out of the box.

Run
---

Start the container:

```bash
docker run -p 2181:2181 -p 9092:9092 --env ADVERTISED_HOST=localhost --env ADVERTISED_PORT=9092 mkasberg/kafka:0.10.1.0
```

Write a test message to kafka:

```bash
kafka-console-producer.sh --broker-list localhost:9092 --topic test
```

Read the test message:

```bash
kafka-console-consumer.sh --bootstrap-server localhost:9092 --from-beginning --topic test
```

In the box
---
* **mkasberg/kafka**

  The docker image with both Kafka and Zookeeper. Built from the `kafka`
  directory.

Public Builds
---

https://hub.docker.com/r/mkasberg/kafka/

Build from Source
---

    docker build -t mkasberg/kafka kafka/

Todo
---

* Not particularily optimzed for startup time.
* Better docs

