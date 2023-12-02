#! /bin/bash
source env.sh
set -x
CNAME=sambad
podman port "$CNAME"
# LDAPTLS_CACERT="$SMB_CA" ldapsearch -H "ldaps://$SMB_HOSTNAME:1636" -LLL -D '' -w "$SMB_ADMIN_PASSWORD" -b "$SMB_OU" '(samaccountname=santa)' dn
