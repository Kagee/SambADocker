#! /bin/bash
source env.sh

PRIVATE=$(realpath files/private)

echo "This script will delete all data in $PRIVATE.
Press ENTER to continue, CTRL-C to cancel:"
read -r

rm -r "$PRIVATE" || true
mkdir -p "$PRIVATE"
touch "$PRIVATE/.gitkeep"

ALT_NAMES=""
CN=""
if [[ -n $OPENSSL_DNS ]]; then
  loop=1
  while read -r FQDN;
  do
    if [[ $loop == "1" ]]; then
      CN="$FQDN"
    fi
    ALT_NAMES="$ALT_NAMES
DNS.$loop = $FQDN"
    ((loop++))
  done < <(echo "$OPENSSL_DNS" | tr ',' "\n")
fi
if [[ -n $OPENSSL_IPS ]]; then
  loop=1
  while read -r IP;
  do
    ALT_NAMES="$ALT_NAMES
IP.$loop = $IP"
    ((loop++))
  done < <(echo "$OPENSSL_IPS" | tr ',' "\n")
fi

if ! [[ "$OPENSSL_DNS" == *"$LDAP_HOSTNAME"* ]]; then
  echo "OPENSSL_DNS must contain LDAP_HOSTNAME"
  exit 1
fi

if [[ $ALT_NAMES = "" ]]; then
  echo "Must specify OPENSSL_DNS or OPENSSL_IPS in .env" 1>&2
  exit
fi
if [[ $CN = "" ]]; then
  echo "Must specify atleast one hostname in OPENSSL_DNS in .env" 1>&2
  exit
fi
OPENSSL_CNF=$(cat <<END
[ req ]
prompt = no
default_bits        = 2048
days = 90
distinguished_name  = req_distinguished_name
[req_distinguished_name]
commonName             = $CN
[ san ]
subjectAltName         = @alt_names
[ alt_names ]$ALT_NAMES
END
)


CA_NAME="SambADocker AUTOGENERATED TESTING CA"
CA_DIR="$PRIVATE/ca"
mkdir -p "$CA_DIR"

echo "Generating CA private key: $CA_DIR/ca.key"
openssl genrsa -out "$CA_DIR/ca.key" 4096
echo "Generating CA certificate: $CA_DIR/ca.crt"
openssl req \
  -x509 \
  -sha256 \
  -new \
  -nodes \
  -key "$CA_DIR/ca.key" \
  -days 90 \
  -out "$CA_DIR/ca.crt" \
  -subj "/CN=$CA_NAME"
echo "CA Details:"
openssl x509 \
  -in "$CA_DIR/ca.crt" \
  -noout \
  -issuer \
  -subject \
  -dates \
  -fingerprint \
  -ext basicConstraints | \
  while read -r L; do echo -e "\t$L"; done

CERT_DIR="$PRIVATE/cert"
mkdir -p "$CERT_DIR"

echo "Writing certificate config $CERT_DIR/cert.cnf"
echo "$OPENSSL_CNF" > "$CERT_DIR/cert.cnf"
echo "Generating Certificate signing request and key $CERT_DIR/cert.csr $CERT_DIR/cert.key"
openssl req \
  -new \
  -nodes \
  -out "$CERT_DIR/cert.csr" \
  -newkey rsa:4096 \
  -config "$CERT_DIR/cert.cnf" \
  -extensions san \
  -keyout "$CERT_DIR/cert.key"
echo "Generating and signing certificate $CERT_DIR/cert.crt"
openssl x509 -req \
  -in "$CERT_DIR/cert.csr" \
  -CA "$CA_DIR/ca.crt" \
  -CAkey "$CA_DIR/ca.key" \
  -CAcreateserial \
  -days 90 \
  -out "$CERT_DIR/cert.crt" \
  -extfile "$CERT_DIR/cert.cnf" \
  -extensions san

echo "Certificate Details:"
openssl x509 -in "$CERT_DIR/cert.crt" -noout -issuer -subject -dates -fingerprint -ext subjectAltName | \
  while read -r L; do echo -e "\t$L"; done