# Kernel Message Logger

Implements a kernel message reader and Redis integration.
Adds functionality to read kernel messages from `/dev/kmsg` and store
them in a Redis stream named "kmsg". Utilises a repeat-fail loop
to continuously read messages until termination. Includes parsing
logic for message components using DCG rules.
