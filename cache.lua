local _M = {}

local function vary_by_headers(vary_headers, cache_key)
    local headers = ngx.req.get_headers()
    table.sort(headers)
    for _, header in ipairs(vary_headers) do
        local header_value = headers[header]
        if header_value then
          if type(header_value) == "table" then
            table.sort(header_value)
            header_value = table.concat(header_value, ",")
          end
          ngx.log(ngx.DEBUG, "varying cache key by matched header ("..header..":"..header_value..")")
          cache_key = cache_key..":"..header.."="..header_value
        else
            ngx.log(ngx.DEBUG, "header not found ("..header..")")
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

function _M:generate_cache_key()
    local cache_key = ngx.req.get_method()..':'..ngx.var.request_uri
    if self.config.vary_headers then
        cache_key = vary_by_headers(self.config.vary_headers, cache_key)
    end
    return string.lower(cache_key)
end

function _M:cache_control_enabled()
    local cache_control = ngx.req.get_headers()['cache-control']
    ngx.log(ngx.DEBUG, "Cache-Control: ", cache_control)
    return cache_control and cache_control == 'no-cache' and self.config.cache_control
end

function _M:cache_ttl()
    if self.cache_control_enabled() then
        local cache_control = ngx.req.get_headers()['cache-control']
        local max_age = string.match(cache_control, '[max-age=](%d+)')
        ngx.log(ngx.DEBUG, "max-age: ", max_age)
        if max_age then
            return tonumber(max_age)
        end
    end
    return self.config.cache_ttl
end

return _M