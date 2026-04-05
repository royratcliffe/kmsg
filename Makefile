IMAGE := kmsg
TAG := $(shell git describe --tags --always --dirty)

.PHONY: build
build:
	docker build -t $(IMAGE) -t $(IMAGE):$(TAG) -t $(IMAGE):latest -t royratcliffe/$(IMAGE):latest .

.PHONY: run
run: build
	docker run --device=/dev/kmsg --network=host --rm $(IMAGE):latest -v
