all: start configure

start:
	docker compose up -d

clean:
	docker compose down -v

configure:
	./scripts/wait-for-response.sh \
		http://keycloak.traefik.me:8080/realms/master/protocol/openid-connect/token \
		&& terraform apply -auto-approve
