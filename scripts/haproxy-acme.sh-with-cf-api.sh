#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root." 
   exit 1
fi

prompt_var() {
  local var_name=$1
  local var_value="${!var_name}"

  while [ -z "$var_value" ]; do
    read -p "Set the variable $var_name: " var_value
  done

  export $var_name="$var_value"
}

validate_email() {
    [[ $1 =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$ ]] && [[ ! $1 == *@example.com ]]
}

for var in domain email CF_Token TROJAN_PASSWORDS; do
  prompt_var $var
done

if ! validate_email "$email"; then
  echo "Invalid email address ( @example.com not supported )."
  exit 1
fi

if [ ! -f "$TROJAN_PASSWORDS" ]; then
  bash scripts/generate-passwords.sh $TROJAN_PASSWORDS
fi

export DEBIAN_FRONTEND=noninteractive

apt update && apt install -y curl grep jq openssl

bash scripts/test-cf-token.sh
if [ $? -ne 0 ]; then
  echo "Error during testing of CloudFlare API token."
  exit 1
fi

apt install -y haproxy cron socat

mkdir /etc/haproxy/certs
chown haproxy:haproxy /etc/haproxy/certs
chmod 770 /etc/haproxy/certs

openssl dhparam -out /etc/haproxy/dhparam.pem 2048

bash scripts/write.sh configs/haproxy.cfg /etc/haproxy/haproxy.cfg
bash scripts/auth.lua.gen.sh $TROJAN_PASSWORDS

curl https://get.acme.sh | sh -s email=$email
/root/.acme.sh/acme.sh --set-default-ca --server letsencrypt

export CF_Token
/root/.acme.sh/acme.sh --issue --dns dns_cf --ocsp -k 2048 -d $domain -d "*.$domain"
/root/.acme.sh/acme.sh --issue --dns dns_cf --ocsp -k ec-256 -d $domain -d "*.$domain"

export DEPLOY_HAPROXY_STATS_SOCKET="UNIX:/var/run/haproxy/admin.sock"
export DEPLOY_HAPROXY_PEM_PATH="/etc/haproxy/certs"
export DEPLOY_HAPROXY_BUNDLE="yes"
/root/.acme.sh/acme.sh --deploy -d $domain --deploy-hook haproxy
/root/.acme.sh/acme.sh --deploy --ecc -d $domain --deploy-hook haproxy
systemctl restart haproxy

cp /root/.acme.sh/$domain/ca.cer /etc/haproxy/certs/$domain.pem.rsa.issuer
cp /root/.acme.sh/${domain}_ecc/ca.cer /etc/haproxy/certs/$domain.pem.ecdsa.issuer

/root/.acme.sh/acme.sh --deploy -d $domain --deploy-hook haproxy
/root/.acme.sh/acme.sh --deploy --ecc -d $domain --deploy-hook haproxy

systemctl restart haproxy
systemctl enable haproxy.service
