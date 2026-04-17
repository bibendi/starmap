.PHONY: build run shell stop logs run-prod shell-prod

IMAGE ?= starmap
PROD_IMAGE ?= bibendi/starmap:latest
PLATFORM ?= --platform linux/amd64
PORT ?= 3000
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

run-prod:
	docker pull $(PLATFORM) $(PROD_IMAGE)
	docker run -d --name starmap_prod $(PLATFORM) \
		-p $(PORT):3000 \
		-e SECRET_KEY_BASE=$(SECRET_KEY_BASE) \
		-e RAILS_FORCE_SSL=false \
		-e RAILS_ASSUME_SSL=false \
		-e DATABASE_URL=$(DATABASE_URL) \
		$(PROD_IMAGE)

shell-prod:
	docker pull $(PLATFORM) $(PROD_IMAGE)
	docker run -it --rm $(PLATFORM) \
		-e SECRET_KEY_BASE=$(SECRET_KEY_BASE) \
		-e DATABASE_URL=$(DATABASE_URL) \
		--entrypoint /bin/bash \
		$(PROD_IMAGE)

stop:
	docker rm -f starmap 2>/dev/null; docker rm -f starmap_prod 2>/dev/null || true

logs:
	docker logs -f starmap

logs-prod:
	docker logs -f starmap_prod
