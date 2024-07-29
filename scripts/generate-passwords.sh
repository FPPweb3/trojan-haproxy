#!/bin/bash

TROJAN_PASSWORDS="$1"

for i in {1..3}; do
  PASSWORD=$(tr -dc 'A-Za-z0-9!#$%&()*+,-./:;<=>?@[]^_`{|}~' </dev/urandom | head -c 12; echo)
  echo "$PASSWORD" >> "$TROJAN_PASSWORDS"
done
