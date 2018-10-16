build:
	docker-compose -f docker-compose.yml -f docker-compose.local.yml build

serve:
	-rm tmp/pids/server.pid &> /dev/null
	docker-compose up

bundle:
	docker-compose run --rm app bundle
	docker-compose build

test:
	docker-compose run --rm app rspec

shell:
	docker-compose exec app /bin/bash
