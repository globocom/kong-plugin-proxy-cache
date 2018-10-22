local _M = {}

local function append_to_cache_key(cache_key, list, allowlist)
    local ordered_list = list
    table.sort(ordered_list)
    for _, allowed in ipairs(allowlist) do
        local value = ordered_list[allowed]
        if value then
            if type(value) == "table" then
                table.sort(value)
                value = table.concat(value, ",")
            end
            cache_key = cache_key..":"..allowed.."="..value
        end
    end
    return cache_key
end

function _M:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function _M:set_config(config)
    self.config = config or {}
end

function _M:generate_cache_key(request, nginx_variables)
    local cache_key = nginx_variables.host..':'..request.get_method()..':'..nginx_variables.request_uri
    if self.config.vary_headers then
        cache_key = append_to_cache_key(cache_key, request.get_headers(), self.config.vary_headers)
    end
    if self.config.vary_nginx_variables then
        cache_key = append_to_cache_key(cache_key, nginx_variables, self.config.vary_nginx_variables)
    end
    return string.lower(cache_key)
end

function _M:cache_ttl()
    if self.config.cache_control then
        local cache_control = ngx.header['cache-control'] or ''
        return string.match(cache_control, '[max-age=](%d+)')
    end
    return self.config.cache_ttl
end

return _M
