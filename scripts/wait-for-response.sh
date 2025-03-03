#!/usr/bin/env bash

set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

wait() {
  echo "Checking HTTP response for $1"
  timeout 90 bash -c \
    'http_code="$(curl -s -o /dev/null -w ''%{http_code}'' ${0})"; while (( http_code < 200 || http_code >= 500 )) ;\
      do echo "Waiting ... $http_code" && sleep 5;\
      http_code="$(curl -s -o /dev/null -w ''%{http_code}'' ${0})";\
      done' "$1"
  echo "HTTP response OK"
}

wait "$1"
