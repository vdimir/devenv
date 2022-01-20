

.PHONY: all
all: image

.PHONY: image
image:
	docker build --build-arg UID=$(shell id -u) --build-arg GID=$(shell id -g) -t ubuntu_dev .

.PHONY: run
run:
	docker run -d -P ubuntu_dev

