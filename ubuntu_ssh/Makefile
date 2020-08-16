
.PHONY: image run

image:
	docker build --build-arg UID=$(id -u) --build-arg GID=$(id -g) -t ubuntu_dev .

run:
	docker run -d -P ubuntu_dev

