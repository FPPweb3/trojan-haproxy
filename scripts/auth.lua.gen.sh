#!/bin/bash

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root."
   exit 1
fi

TROJAN_PASSWORDS="$1"
OUTPUT_LUA="/etc/haproxy/auth.lua"

echo "
local passwords = {" > $OUTPUT_LUA

while IFS= read -r line
do
  echo "    [\"$(echo -n "$line" | openssl dgst -sha224 | sed 's/.* //')\"] = true,	-- $line" >> $OUTPUT_LUA
done < $TROJAN_PASSWORDS

tac $OUTPUT_LUA | sed '0,/,/{s/,/\t/}' | tac > /tmp/auth-gen.temp && mv /tmp/auth-gen.temp $OUTPUT_LUA

echo "}

function trojan_auth(txn)
    local status, data = pcall(function() return txn.req:dup() end)
    if status and data then
        -- Uncomment to enable logging of all received data
        -- core.Info(\"Received data from client: \" .. data)
        local sniffed_password = string.sub(data, 1, 56)
        -- Uncomment to enable logging of sniffed password hashes
        -- core.Info(\"Sniffed password: \" .. sniffed_password)
        if passwords[sniffed_password] then
            return \"trojan\"
        end
    end
    return \"http\"
end

core.register_fetches(\"trojan_auth\", trojan_auth)" >> $OUTPUT_LUA

systemctl reload haproxy.service
