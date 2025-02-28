terraform {
  required_providers {
    keycloak = {
      source  = "keycloak/keycloak"
      version = ">= 5.0.0"
    }
  }
}

# Keycloak

provider "keycloak" {
  client_id = "admin-cli"
  username  = "admin"
  password  = "admin"
  url       = "http://keycloak.traefik.me:8080"

}

resource "keycloak_realm" "main" {
  realm = "playground"
}

resource "keycloak_openid_client" "main" {
  realm_id                   = keycloak_realm.main.id
  client_id                  = "demo"
  access_type                = "CONFIDENTIAL"
  standard_flow_enabled      = true
  valid_redirect_uris        = ["*"]
  pkce_code_challenge_method = "S256"
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

data "keycloak_openid_client" "main" {
  realm_id  = keycloak_realm.main.id
  client_id = keycloak_openid_client.main.client_id
}

# show public key of first key:
output "public_key" {
  value = data.keycloak_realm_keys.realm_keys.keys[0].public_key
}

# show main client name 
output "client_id" {
  value = data.keycloak_openid_client.main.client_id
}

# show main client secret
output "client_secret" {
  value     = data.keycloak_openid_client.main.client_secret
  sensitive = true
}

