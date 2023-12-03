#! /bin/bash
source env.sh
function green { printf "\033[1;32m%s\033[0m\n" "$1"; }
function red { printf "\033[0;31m%s\033[0m\n" "$1"; }
function bro { printf "\033[0;33m%s\033[0m\n" "$1"; }

if [[ -z "$(dig +short "$LDAP_HOSTNAME")" ]]; then
  echo "LDAP_HOSTNAME ($LDAP_HOSTNAME) is not pointing to anything!" 1>&2
  exit 1
fi

if ! command -v ldapsearch 1>/dev/null; then
  echo "ldapsearch is not installed!" 1>&2
  exit 1
fi

TLS_OK=false
TLS_HOSTNAME_OK=false
PREPEND_CA=false
CA="./files/private/ca/ca.crt"

echo -n "Testing if openssl trusts CA used for $LDAP_HOSTNAME:$HOST_PORT_LDAPS using system ca store... "
if ! { echo | openssl s_client -verify_return_error -connect "$LDAP_HOSTNAME:$HOST_PORT_LDAPS" 1>/dev/null 2>&1; }; then
  red "FAIL"
else
  green "OK"
  TLS_OK=true
  echo -n "Testing if certificate for $LDAP_HOSTNAME:$HOST_PORT_LDAPS has correct hostname... "
  if ! { echo | openssl s_client -verify_return_error -verify_hostname "$LDAP_HOSTNAME" -connect "$LDAP_HOSTNAME:$HOST_PORT_LDAPS" 1>/dev/null 2>&1; }; then
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
  echo -n "Testing if openssl trusts CA used for $LDAP_HOSTNAME:$HOST_PORT_LDAPS when supplied... "
  if ! { echo | openssl s_client -verify_return_error -verifyCAfile "$CA" -connect "$LDAP_HOSTNAME:$HOST_PORT_LDAPS" 1>/dev/null 2>&1; }; then
    red "FAIL"
  else
    green "OK"
    TLS_OK=true
    PREPEND_CA=true
    echo -n "Testing if certificate for $LDAP_HOSTNAME:$HOST_PORT_LDAPS has correct hostname... ";
    if ! { echo | openssl s_client -verify_return_error -verifyCAfile "$CA" -verify_hostname "$LDAP_HOSTNAME" -connect "$LDAP_HOSTNAME:$HOST_PORT_LDAPS" 1>/dev/null 2>&1; }; then
      red "FAIL"
      red "You LDAP server does not answer with a certificate that is valid for $LDAP_HOSTNAME"
      bro "$(echo | openssl s_client -verifyCAfile "$CA" -connect "$LDAP_HOSTNAME:$HOST_PORT_LDAPS" 2>&1 | openssl x509 -noout -subject -ext subjectAltName)"
      exit 1
    else
      green "OK"
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
echo -n "Testing unencrypted LDAP at $LDAP_HOSTNAME:$HOST_PORT_LDAP... "
LDAP_STDOUT=$(ldapsearch -H "ldap://$LDAP_HOSTNAME:$HOST_PORT_LDAP" -w "invalid" 2>&1)
if [[ $? -eq 49 ]]; then
  green "OK - Invalid credentials (49)"
else
 red "FAIL"
 red "Did not get expected Invalid credentials (49)":
 bro "$LDAP_STDOUT"
 exit 1
fi
echo -n "Testing LDAP+STARTTLS at $LDAP_HOSTNAME:$HOST_PORT_LDAP... ";
LDAP_STDOUT=$(ldapsearch -ZZ -H "ldap://$LDAP_HOSTNAME:$HOST_PORT_LDAP" -w "invalid" 2>&1)
if [[ $? -eq 49 ]]; then
  green "OK - Invalid credentials (49)"
else
 red "FAIL"
 red "Did not get expected Invalid credentials (49)":
 bro "$LDAP_STDOUT"
 exit 1
fi
echo -n "Testing LDAP+TLS/SSL at $LDAP_HOSTNAME:$HOST_PORT_LDAPS... ";
LDAP_STDOUT=$(ldapsearch -H "ldaps://$LDAP_HOSTNAME:$HOST_PORT_LDAPS" -w "invalid" 2>&1)
if [[ $? -eq 49 ]]; then
  green "OK - Invalid credentials (49)"
else
 red "FAIL"
 red "Did not get expected Invalid credentials (49)":
 bro "$LDAP_STDOUT"
 exit 1
fi
bro "Connection tests OK. Will continue on LDAP+STARTTLS"
echo -n "Testing auth using Administrator account 'CN=Administrator,CN=Users,$LDAP_OU' / '$LDAP_ADMIN_PASSWORD'... ";
if LDAP_STDOUT=$(ldapsearch \
  -ZZ \
  -H "ldap://$LDAP_HOSTNAME:$HOST_PORT_LDAP" \
  -D "CN=Administrator,CN=Users,$LDAP_OU" \
  -w "$LDAP_ADMIN_PASSWORD" \
  -b "$LDAP_OU" \
  "dn=CN=Administrator,CN=Users,$LDAP_OU" 2>&1); then
  green "OK - Success (0)"
else
 red "FAIL"
 red "Did not get expected Success (0)":
 bro "$LDAP_STDOUT"
 exit 1
fi
echo -n "Testing auth using santa account '$LDAP_DOMAIN\\$USER1_SAN' / '$USER1_PW'... ";
if LDAP_STDOUT=$(ldapsearch \
  -ZZ \
  -H "ldap://$LDAP_HOSTNAME:$HOST_PORT_LDAP" \
  -D "$LDAP_DOMAIN\\$USER1_SAN" \
  -w "$USER1_PW" \
  -b "$LDAP_OU" \
  "dn=CN=Administrator,CN=Users,$LDAP_OU" 2>&1); then
  green "OK - Success (0)"
else
 red "FAIL"
 red "Did not get expected Success (0)":
 bro "$LDAP_STDOUT"
 exit 1
fi
echo -n "Testing auth using $SERVICE_USER1_SAN service account '$SERVICE_USER1_SAN@$LDAP_REALM' / '$SERVICE_USET1_PW'... ";
if LDAP_STDOUT=$(ldapsearch \
  -ZZ \
  -H "ldap://$LDAP_HOSTNAME:$HOST_PORT_LDAP" \
  -D "$SERVICE_USER1_SAN@$LDAP_REALM" \
  -w "$SERVICE_USET1_PW" \
  -b "$LDAP_OU" \
  "dn=CN=Administrator,CN=Users,$LDAP_OU" 2>&1); then
  green "OK - Success (0)"
else
 red "FAIL"
 red "Did not get expected Success (0)":
 bro "$LDAP_STDOUT"
 exit 1
fi
