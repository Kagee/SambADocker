#!/bin/bash

set -e

echo "[INFO] Running setup"

# Check if samba is setup
[ -f /var/lib/samba/.setup ] && echo "[INFO] Already setup..." && exit 0

echo "[INFO] Provisioning domain controller..."

rm /etc/samba/smb.conf || true

# Required for rotless docker since 
# we have a limit on ids
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

# posix:eadb is required for rootless docker
# since we will be lackin xattr support
samba-tool domain provision \
 --server-role=dc \
 --use-rfc2307 \
 --dns-backend=SAMBA_INTERNAL \
 --realm="${SMB_REALM}" \
 --domain="${SMB_DOMAIN}" \
 --adminpass="${SMB_ADMIN_PASSWORD}" \
 --option="posix:eadb = /var/lib/samba/private/eadb.tdb"

# (if a) TLS key is configured, make samba use
# it and not generate one on it's own
if [ -n "${SMB_KEY}" ]; then
       sed  "/posix:eadb/a tls enabled  = yes\ntls keyfile  = ${SMB_KEY}\ntls certfile = ${SMB_CERT}\ntls cafile   = ${SMB_CA}\n" -i /etc/samba/smb.conf
fi

mv /etc/samba/smb.conf /var/lib/samba/private/smb.conf
touch /var/lib/samba/.setup
