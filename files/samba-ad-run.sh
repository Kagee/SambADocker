#!/bin/bash
 
set -e
SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

$SCRIPT_DIR/samba-ad-setup.sh

[ -f /var/lib/samba/.setup ] || {
    >&2 echo "[ERROR] Samba is not setup yet, which should happen automatically. Look for errors!"
    exit 127
}

[[ ! -f "" ]] && cp /var/lib/samba/private/krb5.conf /etc/krb5.conf

samba -i -s /var/lib/samba/private/smb.conf
