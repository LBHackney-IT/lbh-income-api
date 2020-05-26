
.PHONY: docker-build
docker-build:
	docker-compose build

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
	docker-compose up

.PHONY: shell
shell:
	docker-compose run --rm app /bin/bash

.PHONY: test-db-destroy
test-db-destroy:
	docker-compose rm --stop -v incomeapi-db

.PHONY: test
test:
	docker-compose run --rm -e "RAILS_ENV=test" app rspec

.PHONY: lint
lint:
	docker-compose run --rm -e RAILS_ENV=test app rubocop

.PHONY: check
check: lint test
	echo 'Deployable!'

guard:
	docker-compose run --rm app guard
