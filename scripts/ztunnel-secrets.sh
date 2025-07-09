#!/bin/bash

openssl genrsa -out private.key 2048

echo '[ req ]
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[ req_distinguished_name ]
O = cluster.local

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical,CA:TRUE
keyUsage = critical,keyCertSign' > openssl.conf

openssl req -x509 -new -nodes -key private.key -sha256 -days 3650 -out root.crt -config openssl.conf

kubectl --namespace kube-system create secret generic cilium-ztunnel-secrets \
      --from-file=private.key=private.key \
      --from-file=root.crt=root.crt
