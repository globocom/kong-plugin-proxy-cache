local function server_port(given_value, given_config)
    if given_value > 65534 then
        return false, "port value too high"
    end
end

return {
    no_consume = true,

    fields = {
        response_code = {
            type = "array",
            default = {"200", "301", "302"},
            required = true
        },
        vary_headers = {
            type = "array",
            required = false
        },
        vary_nginx_variables = {
            type = "array",
            required = false
        },
        cache_ttl = {
            type = "number",
            default = 300,
            required = true
        },
        cache_control = {type = "boolean", default = true},
        redis = {
            type = "table",
            schema = {
                fields = {
                    host = {type = "string", required = false},
                    sentinel_master_name = {type = "string", required = false},
                    sentinel_role = {type = "string", required = false, default = "master"},
                    sentinel_addresses = {type = "array", required = false},
                    port = {
                        type = "number",
                        func = server_port,
                        default = 6379,
                        required = true
                    },
                    timeout = {type = "number", required = true, default = 2000},
                    password = {type = "string", required = false},
                    database = {type = "number", required = true, default = 0},
                    max_idle_timeout = {type = "number", required = true, default = 10000},
                    pool_size = {type = "number", required = true, default = 1000}
                }
            }
        }
    }
}
