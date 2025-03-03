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
  url       = "https://keycloak.traefik.me"

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

resource "keycloak_authentication_flow" "main" {
  alias       = "passkeys flow"
  description = "Browser based authentication with Passkeys"
  provider_id = "basic-flow"
  realm_id    = keycloak_realm.main.realm
}

# first execution
resource "keycloak_authentication_execution" "execution_one" {
  realm_id          = keycloak_realm.main.id
  parent_flow_alias = keycloak_authentication_flow.main.alias
  authenticator     = "auth-cookie"
  priority          = 10
  requirement       = "ALTERNATIVE"
}

resource "keycloak_authentication_execution" "kerberos" {
  realm_id          = keycloak_realm.main.id
  parent_flow_alias = keycloak_authentication_flow.main.alias
  authenticator     = "auth-spnego"
  priority          = 20
}

# second execution
resource "keycloak_authentication_execution" "idp-redirect" {
  realm_id          = keycloak_realm.main.id
  parent_flow_alias = keycloak_authentication_flow.main.alias
  authenticator     = "identity-provider-redirector"
  priority          = 30
  requirement       = "ALTERNATIVE"

  depends_on = [
    keycloak_authentication_execution.execution_one
  ]
}

resource "keycloak_authentication_execution" "passkeys-auth" {
  realm_id          = keycloak_realm.main.id
  parent_flow_alias = keycloak_authentication_flow.main.alias
  authenticator     = "passkeys-authenticator"
  priority          = 40
  requirement       = "ALTERNATIVE"
}

# resource "keycloak_authentication_execution" "idp-form" {
#   realm_id          = keycloak_realm.main.id
#   parent_flow_alias = keycloak_authentication_flow.main.alias
#   authenticator     = "identity-provider-form"
#   requirement       = "ALTERNATIVE"
# 
#   depends_on = [
#     keycloak_authentication_execution.idp-redirect
#   ]
# }

resource "keycloak_authentication_subflow" "organisation" {
  realm_id          = keycloak_realm.main.id
  alias             = "PKFlow - Organisation"
  parent_flow_alias = keycloak_authentication_flow.main.alias
  priority          = 50
  requirement       = "ALTERNATIVE"
}

resource "keycloak_authentication_subflow" "browser-conditional-organisation" {
  realm_id          = keycloak_realm.main.id
  alias             = "PKFlow - Conditional Organisation"
  parent_flow_alias = keycloak_authentication_subflow.organisation.alias
  requirement       = "CONDITIONAL"
}

resource "keycloak_authentication_execution" "condition-organisation-user-configured" {
  realm_id          = keycloak_realm.main.id
  parent_flow_alias = keycloak_authentication_subflow.browser-conditional-organisation.alias
  authenticator     = "conditional-user-configured"
  priority          = 10
  requirement       = "REQUIRED"
}

resource "keycloak_authentication_execution" "condition-organisation-configured" {
  realm_id          = keycloak_realm.main.id
  parent_flow_alias = keycloak_authentication_subflow.browser-conditional-organisation.alias
  authenticator     = "organization"
  priority          = 20
  requirement       = "ALTERNATIVE"
}

resource "keycloak_authentication_subflow" "forms" {
  realm_id          = keycloak_realm.main.id
  alias             = "PKFlow - Forms"
  description       = "Username, password, OTP and other auth forms"
  parent_flow_alias = keycloak_authentication_flow.main.alias
  priority          = 60
  requirement       = "ALTERNATIVE"
}

resource "keycloak_authentication_execution" "forms_username" {
  realm_id          = keycloak_realm.main.id
  parent_flow_alias = keycloak_authentication_subflow.forms.alias
  authenticator     = "auth-username-password-form"
  priority          = 10
  requirement       = "REQUIRED"
}

resource "keycloak_authentication_subflow" "browser_conditional_otp" {
  realm_id          = keycloak_realm.main.id
  alias             = "PKFlow - Conditional OTP"
  description       = "Flow to determine if a OTP is required for the authentication"
  parent_flow_alias = keycloak_authentication_subflow.forms.alias
  priority          = 20
  requirement       = "CONDITIONAL"
}

resource "keycloak_authentication_execution" "condition-user-configured" {
  realm_id          = keycloak_realm.main.id
  parent_flow_alias = keycloak_authentication_subflow.browser_conditional_otp.alias
  authenticator     = "conditional-user-configured"
  priority          = 10
  requirement       = "REQUIRED"
}

resource "keycloak_authentication_execution" "otp-form" {
  realm_id          = keycloak_realm.main.id
  parent_flow_alias = keycloak_authentication_subflow.browser_conditional_otp.alias
  authenticator     = "auth-otp-form"
  priority          = 20
  requirement       = "ALTERNATIVE"
}

resource "keycloak_authentication_execution" "webauthn-authenticator" {
  realm_id          = keycloak_realm.main.id
  parent_flow_alias = keycloak_authentication_subflow.browser_conditional_otp.alias
  authenticator     = "webauthn-authenticator-passwordless"
  priority          = 30
  requirement       = "ALTERNATIVE"
}

resource "keycloak_authentication_bindings" "browser_authentication_binding" {
  realm_id     = keycloak_realm.main.id
  browser_flow = keycloak_authentication_flow.main.alias
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

resource "local_file" "public_key" {
  content  = "-----BEGIN PUBLIC KEY-----\n${data.keycloak_realm_keys.realm_keys.keys[0].public_key}\n-----END PUBLIC KEY-----"
  filename = "public.pem"
}

