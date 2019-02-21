COMPOSE_FILES = -f docker-compose.yml #-f docker-compose.local.yml

.PHONY: docker-build
docker-build:
	docker-compose $(COMPOSE_FILES) build

.PHONY: docker-down
docker-down:
	docker-compose down

.PHONY: bundle
bundle:
	docker-compose run --rm app bundle

.PHONY: setup
setup: docker-build bundle

.PHONY: serve
serve:
	-rm tmp/pids/server.pid &> /dev/null
	docker-compose $(COMPOSE_FILES) up

.PHONY: test
test:
	docker-compose run --rm app rspec

.PHONY: shell
shell:
	docker-compose run --rm app /bin/bash

.PHONY: lint
lint:
	docker-compose run --rm app rubocop

.PHONY: check
check: lint test
	echo 'Deployable!'

guard:
	docker-compose run --rm app guard
