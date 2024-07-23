#!/bin/bash

for cmd in curl grep jq openssl; do
  if ! command -v "$cmd" &> /dev/null; then
    echo "ERROR: $cmd is not installed."
    exit 1
  fi
done

if [ -z "$CF_Token" ] || [ -z "$domain" ]; then
  echo "ERROR: CF_Token || domain is not set"
  exit 1
fi

test_rand_id=$(openssl rand -hex 16)

test_suffix1=$(echo "$domain" | grep -oP '[^.]+\.[^.]+$')	# example.com
test_suffix2=$(echo "$domain" | grep -oP '([^.]+\.[^.]+\.[^.]+)$')	# example.us.com

test_response=$(curl --silent --request GET \
  --url https://api.cloudflare.com/client/v4/zones \
  --header "Authorization: Bearer $CF_Token" \
  --header "Content-Type: application/json")

test_zone_id=$(echo $test_response | jq -r --arg test_suffix1 "$test_suffix1" --arg test_suffix2 "$test_suffix2" '.result[] | select(.name==$test_suffix1 or .name==$test_suffix2) | .id' | head -1)


if [ -z "$test_zone_id" ]; then
  echo "ERROR: NOT VALID CF_Tocken: Zone ID for $test_suffix1 and $test_suffix2 not found."
  exit 1
else
  #echo "Zone ID for $MAIN_DOMAIN is $zone_id"
  response_add=$(curl --write-out "%{http_code}" --silent --request POST \
    --url https://api.cloudflare.com/client/v4/zones/$test_zone_id/dns_records \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $CF_Token" \
    --data "{
    \"content\": \"test.example.com\",
    \"name\": \"test-$RANDOM.$domain\",
    \"type\": \"CNAME\",
    \"id\": \"$test_rand_id\"
  }")

  if [ ${response_add: -3} -ne 200 ]; then
    echo "ERROR: NOT VALID CF_Tocken: Failed to add test DNS record"
    exit 1
  fi

  test_rand_id=$(echo $response_add | sed 's/...$//' | jq -r '.result.id')

  response_delete=$(curl --write-out "%{http_code}" --silent --output /dev/null --request DELETE \
    --url https://api.cloudflare.com/client/v4/zones/$test_zone_id/dns_records/$test_rand_id \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $CF_Token")

  if [ "$response_delete" -ne 200 ]; then
    echo "ERROR: NOT VALID CF_Tocken: Failed to delete test DNS record"
    exit 1
  fi
  
fi
