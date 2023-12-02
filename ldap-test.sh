#! /bin/bash
source env.sh
function green {
  printf "\033[1;32m%s\033[0m\n" "$1"
}
function red {
  printf "\033[0;31m%s\033[0m\n" "$1"
}
function bro {
  printf "\033[0;33m%s\033[0m\n" "$1"
}

if [[ -z "$(dig +short "$LDAP_HOSTNAME")" ]]; then
  echo "LDAP_HOSTNAME ($LDAP_HOSTNAME) is not pointing to anything!" 1>&2
  exit 1
fi

if command -v docker 1>/dev/null; then
  RUNTIME=docker
elif command -v podman 1>/dev/null; then
  RUNTIME=podman
else
  echo "Neither docker nor podman appears to be installed!" 1>&2
  exit 1
fi

if ! command -v ldapsearch 1>/dev/null; then
  echo "ldapsearch is not installed!" 1>&2
  exit 1
fi

STARTTLS_OK=false
TLS_OK=false
TLS_HOSTNAME_OK=false
PREPEND_CA=false
CA="./files/private/ca/ca.crt"

echo -n "Testing if openssl trusts CA used for $LDAP_HOSTNAME:$HOST_PORT_LDAPS ... "
if ! { echo | openssl s_client -verify_return_error -connect "$LDAP_HOSTNAME:$HOST_PORT_LDAPS" 1>/dev/null 2>&1; }; then
  red "FAIL"
else
  green "OK"
  TLS_OK=true
  echo -n "Testing if certificate for $LDAP_HOSTNAME:$HOST_PORT_LDAPS has correct hostname... "
  if ! { echo | openssl s_client -verify_return_error -verify_hostname -connect "$LDAP_HOSTNAME:$HOST_PORT_LDAPS" 1>/dev/null 2>&1; }; then
    red "FAIL"
    red "You LDAP server does not answer with a certificate that is valid for $LDAP_HOSTNAME"
    exit 1
  else
    green "OK"
    TLS_HOSTNAME_OK=true
  fi
fi

if ! $TLS_OK; then
  if [[ ! -f "$CA" ]]; then
    red "CA not in system store, and could not read CA from $CA"
    exit 1
  fi
  echo -n "Testing if openssl trusts CA used for $LDAP_HOSTNAME:$HOST_PORT_LDAPS when forced... "
  if ! { echo | openssl s_client -verify_return_error -verifyCAfile "$CA" -connect "$LDAP_HOSTNAME:$HOST_PORT_LDAPS" 1>/dev/null 2>&1; }; then
    red "FAIL"
  else
    green "OK"
    TLS_OK=true
    PREPEND_CA=true
    echo -n "Testing if certificate for $LDAP_HOSTNAME:$HOST_PORT_LDAPS has correct hostname... "
    if ! { echo | openssl s_client -verify_return_error -verifyCAfile "$CA" -verify_hostname -connect "$LDAP_HOSTNAME:$HOST_PORT_LDAPS" 1>/dev/null 2>&1; }; then
      red "FAIL"
      red "You LDAP server does not answer with a certificate that is valid for $LDAP_HOSTNAME"
      bro "$(echo | openssl s_client -verifyCAfile "$CA" -verify_hostname -connect "$LDAP_HOSTNAME:$HOST_PORT_LDAPS" 2>&1 | openssl x509 -noout -subject -ext subjectAltName)"
      exit 1
    else
      green "OK"
      TLS_HOSTNAME_OK=true
    fi
  fi
fi

if $PREPEND_CA; then
  if [[ ! -f "./files/private/ca/ca.crt" ]]; then
    echo "CA not in system store, and could not read CA from ./files/private/ca/ca.crt." 1>&2
    exit 1
  fi
  bro "CA not in system store. Exporting ./files/private/ca/ca.crt as LDAPTLS_CACERT" 1>&2
  export LDAPTLS_CACERT=./files/private/ca/ca.crt
fi
#set -x
#ldapsearch -ZZ -H "ldap://$LDAP_HOSTNAME:$HOST_PORT_LDAP" -d 9

