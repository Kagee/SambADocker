#!/bin/bash

set -e

echo "[INFO] Running setup"

# Check if samba is setup
[ -f /var/lib/samba/.setup ] && echo "[INFO] Already setup..." && exit 0

echo "[INFO] Provisioning domain controller..."

echo "[INFO] Given admin password: ${SMB_ADMIN_PASSWORD}"

rm /etc/samba/smb.conf || true

cat > /usr/share/samba/setup/idmap_init.ldif <<EOF
dn: CN=CONFIG
cn: CONFIG
lowerBound: 655
upperBound: 65533

dn: @INDEXLIST
@IDXATTR: xidNumber
@IDXATTR: objectSid

dn: CN=S-1-5-32-544
cn: S-1-5-32-544
objectClass: sidMap
objectSid: S-1-5-32-544
type: ID_TYPE_BOTH
xidNumber: 655
distinguishedName: CN=S-1-5-32-544
EOF

openssl req -config openssl.cnf -x509 -newkey rsa:2048 -keyout key.pem -nodes -out cert.pem
Add the following to your smb.conf
tls enabled  = yes
tls keyfile  = tls/myKey.pem
tls certfile = tls/myCert.pem
tls cafile   = 

samba-tool domain provision \
 --server-role=dc \
 --use-rfc2307 \
 --dns-backend=SAMBA_INTERNAL \
 --realm="server.dev" \
 --domain=DEV-AD \
 --adminpass="${SMB_ADMIN_PASSWORD}" \
 --option="posix:eadb = /var/lib/samba/private/eadb.tdb"

mv /etc/samba/smb.conf /var/lib/samba/private/smb.conf

touch /var/lib/samba/.setup
