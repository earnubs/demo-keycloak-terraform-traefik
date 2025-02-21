terraform {
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = ">= 5.0.0"
    }
  }
}

provider "keycloak" {
  client_id = "admin-cli"
  username  = "admin"
  password  = "admin"
  url       = "http://localhost:8080"
}

resource "keycloak_realm" "main" {
  realm = "playground"
  # depends_on = [docker_container.keycloak]
}

resource "keycloak_openid_client" "main" {
  realm_id              = keycloak_realm.main.id
  client_id             = "demo"
  access_type           = "CONFIDENTIAL"
  standard_flow_enabled = true
  valid_redirect_uris   = ["*"]
}

resource "keycloak_user" "main" {
  realm_id = keycloak_realm.main.id
  username = "alice"

  email      = "alice@domain.com"
  first_name = "Alice"
  last_name  = "Aliceberg"

  initial_password {
    value = "password"
  }
}

data "keycloak_realm_keys" "realm_keys" {
  realm_id   = keycloak_realm.main.id
  algorithms = ["RS256"]
  status     = ["ACTIVE", "PASSIVE"]
}

# show certificate of first key:
output "certificate" {
  value = data.keycloak_realm_keys.realm_keys.keys[0].certificate
}

# show public key of first key:
output "public_key" {
  value = data.keycloak_realm_keys.realm_keys.keys[0].public_key
}
