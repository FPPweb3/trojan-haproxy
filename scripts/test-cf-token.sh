#!/bin/bash

for cmd in curl grep jq; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "ERROR: $cmd is not installed."
    exit 1
  fi
done

if ! command -v curl &> /dev/null; then
  echo "ERROR: curl is not installed"
  exit 1
fi

if [ -z "$CF_Token" ] || [ -z "$domain" ]; then
  echo "ERROR: CF_Token || domain is not set"
  exit 1
fi

test_rand_id=$(cat /dev/urandom | tr -dc 'a-f0-9' | fold -w 32 | head -n 1)

test_suffix1=$(echo "$domain" | grep -oP '[^.]+\.[^.]+$')	# example.com
test_suffix2=$(echo "$domain" | grep -oP '([^.]+\.[^.]+\.[^.]+)$')	# example.us.com

test_response=$(curl --silent --request GET \
  --url https://api.cloudflare.com/client/v4/zones \
  --header "Authorization: Bearer $CF_Token" \
  --header "Content-Type: application/json")

test_zone_id=$(echo $response | jq -r --arg test_suffix1 "$test_suffix1" --arg test_suffix2 "$test_suffix2" '.result[] | select(.name==$test_suffix1 or .name==$test_suffix2) | .id' | head -1)


if [ -z "$test_zone_id" ]; then
  echo "ERROR: NOT VALID CF_Tocken: Zone ID for $test_suffix1 and $test_suffix2 not found."
  exit 1
else
  #echo "Zone ID for $MAIN_DOMAIN is $zone_id"
  response_add=$(curl --write-out "%{http_code}" --silent --output /dev/null --request POST \
    --url https://api.cloudflare.com/client/v4/zones/$test_zone_id/dns_records \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $CF_Token" \
    --data "{
    \"content\": \"test.example.com\",
    \"name\": \"test-$RANDOM.$domain\",
    \"type\": \"CNAME\",
    \"id\": \"$test_rand_id\"
  }")

  if [ "$response_add" -ne 200 ]; then
    echo "ERROR: NOT VALID CF_Tocken: Failed to add test DNS record"
    exit 1
  fi

  response_delete=$(curl --write-out "%{http_code}" --silent --output /dev/null --request DELETE \
    --url https://api.cloudflare.com/client/v4/zones/$test_zone_id/dns_records/$test_rand_id \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $CF_Token")

  if [ "$response_delete" -ne 200 ]; then
    echo "ERROR: NOT VALID CF_Tocken: Failed to delete test DNS record"
    exit 1
  fi
  
fi
