# Kernel Message Logger

Implements a kernel message reader and Redis integration.
Adds functionality to read kernel messages from `/dev/kmsg` and store
them in a Redis stream named "kmsg". Utilises a repeat-fail loop
to continuously read messages until termination. Includes parsing
logic for message components using DCG rules.

The implementation is designed to be efficient and lightweight, making it suitable for use in various environments, including embedded systems or servers with limited resources. The use of Prolog allows for flexible and powerful parsing capabilities, enabling the extraction of relevant information from kernel messages for further analysis or processing. Overall, this kernel message logger provides a valuable tool for monitoring and analysing kernel messages in real-time, with the potential for further enhancements and integrations to meet specific use cases or requirements.

## Usage

To use the kernel message logger, simply run the Prolog script in a Docker container. It will start reading messages from `/dev/kmsg` and store them in the Redis stream. You can monitor the Redis stream using Redis commands or a Redis client to see the logged kernel messages in real-time.

## Future Enhancements

It connects to the default Redis server at `localhost:6379` but could be configured to connect to a different server if needed. The implementation is designed to be robust, with error handling for connection issues and message parsing errors. Future enhancements could include support for additional message formats if needed, improved error handling, and the ability to filter messages based on specific criteria before storing them in Redis. Additionally, integration with other logging systems or alerting mechanisms could be explored to provide more comprehensive monitoring capabilities.
