# Pac-Man with Elastic Stack

Many people know how awesome is the [Elastic Stack](https://www.elastic.co/elastic-stack) and how powerful each technology from the stack can be.
However, most users struggle to find an end-to-end example based on time series data that makes usage of important features of the stack in a simple to understand scenario.
If that's you then you are in the right place. Meet Pac-Man with Elastic Stack.

<img src="images/pacman.jpg" width="800" height="400">

Kafka is a distributed [commit log](https://engineering.linkedin.com/distributed-systems/log-what-every-software-engineer-should-know-about-real-time-datas-unifying) and therefore messages are immutable and so their ordering within partitions.

## Building the project

The first thing you need to do to start using this partitioner is building it. In order to do that, you need to install the following dependencies:

- [Java 11+](https://openjdk.java.net/)
- [Apache Maven](https://maven.apache.org/)

After installing these dependencies, execute the following command:

```bash
mvn clean package
```

### What about the other topics?

As you may know in Kafka a consumer can subscribe to multiple topics, allowing the same consumer to read messages from partitions belonging to different topics.
Because of this the assignor ensures that only the topic specified in the configuration will have its partitions assigned to the consumers using the bucket priority logic.
The other topics will have their partitions assigned to consumers using a fallback assignor.

Here is an example of configuring the fallback assignor to round-robin:

```bash
configs.setProperty(BucketPriorityConfig.FALLBACK_ASSIGNOR_CONFIG,
   "org.apache.kafka.clients.consumer.RoundRobinAssignor");
```

If you don't configure a fallback assignor explicitly, Kafka's default assignor will be used.

# License

This project is licensed under the [Apache 2.0 License](./LICENSE).
