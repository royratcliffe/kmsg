FROM alpine:latest
RUN apk --no-cache add can-utils swi-prolog --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing --repository=https://dl-cdn.alpinelinux.org/alpine/edge/main
COPY *.pl /srv/
WORKDIR /srv
# Quietly compile the Prolog files and remove the source files to save
# space; the compiled files will be used at runtime.
RUN for pl in *.pl; do swipl -q -t "qcompile('$pl')"; done; rm *.pl
ENTRYPOINT ["swipl", "-s", "kmsg", "--"]
