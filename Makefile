.PHONY: build run shell stop logs

IMAGE ?= starmap
PORT ?= 5100
SECRET_KEY_BASE ?= dummy
DATABASE_URL ?= postgres://postgres:password@host.docker.internal:5432/starmap_production

build:
	docker build -t $(IMAGE) .

run: build
	docker run -d --name starmap \
		-p $(PORT):3000 \
		-e SECRET_KEY_BASE=$(SECRET_KEY_BASE) \
		-e RAILS_FORCE_SSL=false \
		-e RAILS_ASSUME_SSL=false \
		-e DATABASE_URL=$(DATABASE_URL) \
		$(IMAGE)

shell: build
	docker run -it --rm \
		-e SECRET_KEY_BASE=$(SECRET_KEY_BASE) \
		-e DATABASE_URL=$(DATABASE_URL) \
		--entrypoint /bin/bash \
		$(IMAGE)

stop:
	docker rm -f starmap 2>/dev/null || true

logs:
	docker logs -f starmap
