all: start configure

start:
	docker compose up -d

clean:
	docker compose down -v

configure:
	./scripts/wait/wait-for-it.sh localhost:8080 -t 30 --strict -- terraform apply -auto-approve
