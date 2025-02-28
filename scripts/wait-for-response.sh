#!/usr/bin/env bash

set -o errexit  # abort on nonzero exitstatus
set -o nounset  # abort on unbound variable
set -o pipefail # don't hide errors within pipes

wait() {
  echo "Checking HTTP response for $1"
  timeout 60 bash -c \
    'while [[ "$(curl -s -o /dev/null -w ''%{http_code}'' ${0})" < 200 ]];\
    do echo "Waiting..." && sleep 5; done' $1
  echo "HTTP response OK"
}

wait $1
