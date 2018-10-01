local _M = {}

local function vary_by_headers(cache_key, request, vary_headers)
    local headers = request.get_headers()
    table.sort(headers)
    for _, header in ipairs(vary_headers) do
        local header_value = headers[header]
        if header_value then
          if type(header_value) == "table" then
            table.sort(header_value)
            header_value = table.concat(header_value, ",")
          end
          ngx.log(ngx.DEBUG, "varying cache key by matched header ("..header..":"..header_value..")")
          new_cache_key = cache_key..":"..header.."="..header_value
        else
            ngx.log(ngx.DEBUG, "header not found ("..header..")")
        end
    end
    return new_cache_key
end

local function vary_by_nginx_variables(cache_key, nginx_variables, vary_nginx_variables)
    for _, variable in ipairs(vary_nginx_variables) do
        local variable_value = nginx_variables[variable]
        if variable_value then
          if type(variable_value) == "table" then
            table.sort(variable_value)
            variable_value = table.concat(variable_value, ",")
          end
          ngx.log(ngx.DEBUG, "varying cache key by matched nginx variable ("..variable..":"..variable_value..")")
          new_cache_key = cache_key..":"..variable.."="..variable_value
        else
            ngx.log(ngx.DEBUG, "variable not found ("..variable..")")
        end
    end
    return new_cache_key
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
    local cache_key = request.get_method()..':'..nginx_variables.request_uri
    if self.config.vary_headers then
        cache_key = vary_by_headers(cache_key, request, self.config.vary_headers)
    end
    if self.config.vary_nginx_variables then
        cache_key = vary_by_nginx_variables(cache_key, nginx_variables, self.config.vary_nginx_variables)
    end
    return string.lower(cache_key)
end

function _M:check_no_cache()
    if self.config.cache_control then
        local cache_control = ngx.req.get_headers()['cache-control']
        ngx.log(ngx.DEBUG, "Cache-Control: ", cache_control)
        return cache_control and cache_control == 'no-cache'
    end
    return false
end

function _M:cache_ttl()
    if self.config.cache_control then
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
