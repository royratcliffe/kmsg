IMAGE := kmsg
TAG := $(shell git describe --tags --always --dirty)

.PHONY: build
build:
	docker build -t $(IMAGE) -t $(IMAGE):$(TAG) -t $(IMAGE):latest -t royratcliffe/$(IMAGE):latest .

.PHONY: run
run: build
	docker run --device=/dev/kmsg --network=host --rm $(IMAGE):latest -v

.PHONY: install-service
install-service:
	sudo sh install-service.sh

.PHONY: uninstall-service
uninstall-service:
	sudo sh uninstall-service.sh
