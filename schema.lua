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
            default = {"200", "301", "404"},
            required = true
        },
        request_method = {
            type = "array",
            enum = {"GET", "HEAD", "POST", "PUT", "PATCH", "DELETE"},
            default = {"GET", "HEAD"},
            required = true
        },
        vary_headers = {
            type = "array",
            required = false
        },
        cache_ttl = {
            type = "number",
            default = 300,
            required = true
        },
        cache_control = {type = "boolean", default = false},
        redis = {
            type = "table",
            schema = {
                fields = {
                    host = {type = "string", required = true},
                    port = {
                        type = "number",
                        func = server_port,
                        default = 6379,
                        required = true
                    }
                }
            }
        }
    }
}