# Services

Traefik UI: <http://localhost:8081/>

Keycloak UI: <http://keycloak.traefik.me/>

Echo 1: <http://echo-1.traefik.me/>
Echo 2: <http://echo-2.traefik.me/>

# Notes

echo-1 requires authz:

```bash
curl -I echo-1.traefik.me
HTTP/1.1 401 Unauthorized
Content-Type: text/plain; charset=utf-8
X-Content-Type-Options: nosniff
Date: Fri, 28 Feb 2025 21:56:09 GMT
Content-Length: 18
```

echo-2 does not:

```bash
curl -I echo-2.traefik.me
HTTP/1.1 200 OK
Content-Length: 653
Content-Type: application/json; charset=utf-8
Date: Fri, 28 Feb 2025 21:56:58 GMT
Etag: W/"28d-CLMJZ/H/Bce09SvrgCh9CE8HJpA"
```

Authenticate with the client to request a token that will authorise access to the echo-1 service:

```bash
oauth2c http://keycloak.traefik.me/realms/playground \
--grant-type authorization_code \
--client-id "$(terraform output -raw client_id)" \
--client-secret "$(terraform output -raw client_secret)" \
--auth-method client_secret_basic \
--response-types code \
--response-mode query \
--pkce
```

Create an env var $API_TOKEN and use it to access echo-1:

```bash
curl -I -H "Authorization: Bearer $API_TOKEN" http://echo-1.traefik.me/
HTTP/1.1 200 OK
Content-Length: 2018
Content-Type: application/json; charset=utf-8
Date: Fri, 28 Feb 2025 22:00:35 GMT
Etag: W/"7e2-7UrEpdRRxpt52GuN3RToydGhybU"
```

```

```
