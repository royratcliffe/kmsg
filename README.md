# Kernel Message Logger

Implements a kernel message reader and Redis integration. Adds
functionality to read kernel messages from `/dev/kmsg` and store them in
a Redis stream named "kmsg". Utilises a repeat-fail loop to continuously
read messages until termination. Includes parsing logic for message
components using DCG rules.

The implementation is designed to be efficient and lightweight, making
it suitable for use in various environments, including embedded systems
or servers with limited resources. The use of Prolog allows for flexible
and powerful parsing capabilities, enabling the extraction of relevant
information from kernel messages for further analysis or processing.
Overall, this kernel message logger provides a valuable tool for
monitoring and analysing kernel messages in real-time, with the
potential for further enhancements and integrations to meet specific use
cases or requirements.

## Usage

To use the kernel message logger, simply run the Prolog script in a
Docker container. It will start reading messages from `/dev/kmsg` and
store them in the Redis stream. You can monitor the Redis stream using
Redis commands or a Redis client to see the logged kernel messages in
real-time.

The container needs access to the `/dev/kmsg` device, which can be
achieved by running the container with the appropriate permissions. For
example, you can use the following command to run the container with
access to `/dev/kmsg`:

``` bash
docker run --rm -it --device=/dev/kmsg --network=host kmsg
```

## Systemd Service

For running directly on a Linux host, this repository includes
`kmsg.service`.

1. Run the installer script:

``` bash
chmod +x install-service.sh
sudo ./install-service.sh
```

Optional flags:

``` bash
sudo ./install-service.sh --no-enable
sudo ./install-service.sh --no-start
```

2. (Manual alternative) Copy the script and service file to the expected
  locations:

``` bash
sudo install -d /opt/kmsg
sudo install -m 0644 kmsg.pl /opt/kmsg/kmsg.pl
sudo install -m 0644 kmsg.service /etc/systemd/system/kmsg.service
```

3. Verify paths in the service file if you want a different install
   location:

``` bash
sudo systemctl edit --full kmsg.service
```

4. Reload systemd and enable the service:

``` bash
sudo systemctl daemon-reload
sudo systemctl enable --now kmsg.service
```

5. Check service status and logs:

``` bash
systemctl status kmsg.service
journalctl -u kmsg.service -f
```

Notes:

- The service runs as root because reading `/dev/kmsg` typically requires
  elevated privileges.
- `kmsg.service` starts after networking and `redis.service`. If your
  Redis unit has a different name, update the `After=` line.

## Future Enhancements

It connects to the default Redis server at `localhost:6379` but could be
configured to connect to a different server if needed. The
implementation is designed to be robust, with error handling for
connection issues and message parsing errors. Future enhancements could
include support for additional message formats if needed, improved error
handling, and the ability to filter messages based on specific criteria
before storing them in Redis. Additionally, integration with other
logging systems or alerting mechanisms could be explored to provide more
comprehensive monitoring capabilities.
