local passwords = {
    "d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f",	    -- ""
    "78d8045d684abd2eece923758f3cd781489df3a48e1278982466017f",    	-- "123"
    "a9ef569854b55b5a3c21fd087285fc00e9c1aa3b49d03b2df43868f3"	-- "8JCsPssfgS8tiRwiMlhARg=="
}

function select_backend(txn)
    local status, data = pcall(function() return txn.req:dup() end)
    -- Uncomment to enable logging of all received data
    -- core.Info("Received data from client: " .. data)
    if status and data then
        local sniffed_password = string.sub(data, 1, 56)
        -- Uncomment to enable logging of sniffed password hashes
        -- core.Info("Sniffed password: " .. sniffed_password)
        for _, password in ipairs(passwords) do
            if sniffed_password == password then
                return "trojan"
            end
        end
    end
    return "http"
end

core.register_fetches("select_backend", select_backend)
