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

function _M.generate_cache_key(vary_headers)
    local cache_key = ngx.req.get_method()..':'..ngx.var.request_uri
    if vary_headers then
        cache_key = vary_by_headers(vary_headers, cache_key)
    end
    return string.lower(cache_key)
end

return _M