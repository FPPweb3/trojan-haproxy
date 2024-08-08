
local passwords = {
    ["d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f"] = true,		-- ""
    ["78d8045d684abd2eece923758f3cd781489df3a48e1278982466017f"] = true,		-- "123"
    ["a9ef569854b55b5a3c21fd087285fc00e9c1aa3b49d03b2df43868f3"] = true			-- "8JCsPssfgS8tiRwiMlhARg=="
}

function trojan_auth(txn)
    local status, data = pcall(function() return txn.req:dup() end)
    if status and data then
        -- Uncomment to enable logging of all received data
        -- core.Info("Received data from client: " .. data)
        local sniffed_password = string.sub(data, 1, 56)
        -- Uncomment to enable logging of sniffed password hashes
        -- core.Info("Sniffed password: " .. sniffed_password)
        if passwords[sniffed_password] then
            return "trojan"
        end
    end
    return "http"
end

core.register_fetches("trojan_auth", trojan_auth)
