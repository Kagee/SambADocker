#!/bin/bash

set -e

echo "[INFO] Running setup"

# Check if samba is setup
[ -f /var/lib/samba/.setup ] && echo "[INFO] Already setup..." && exit 0

echo "[INFO] Provisioning domain controller..."

echo "[INFO] Given admin password: ${SMB_ADMIN_PASSWORD}"

rm /etc/samba/smb.conf || true
#echo "posix:eadb = /usr/local/samba/private/eadb.tdb" >> /etc/samba/smb.conf

samba-tool domain provision \
 --server-role=dc \
 --use-rfc2307 \
 --dns-backend=SAMBA_INTERNAL \
 --realm="server.dev" \
 --domain=DEV-AD \
 --adminpass="${SMB_ADMIN_PASSWORD}" \
 --option="posix:eadb = /usr/local/samba/private/eadb.tdb"
mv /etc/samba/smb.conf /var/lib/samba/private/smb.conf

touch /var/lib/samba/.setup
