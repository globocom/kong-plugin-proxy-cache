local Storage = require 'kong.plugins.proxy-cache.storage'
local validators = require 'kong.plugins.proxy-cache.validators'
local Cache = require 'kong.plugins.proxy-cache.cache'

local _M = {}

function _M.execute(config)
    ngx.ctx.rt_body_chunks = {}
    ngx.ctx.rt_body_chunk_number = 1

    local storage = Storage:new()
    local cache = Cache:new()
    
    storage:set_config(config)
    cache:set_config(config)

    if cache:check_no_cache() then
        ngx.log(ngx.NOTICE, "[cache-check] cache-control: no-cache")
        ngx.header['X-Cache-Status'] = 'REFRESH'
        return
    end

    if cache:cache_ttl() == nil then
        ngx.log(ngx.NOTICE, "[cache-check] cache TTL is undefined")
        ngx.header['X-Cache-Status'] = 'REFRESH'
        return
    end

    local cache_key = cache:generate_cache_key(ngx.req, ngx.var)

    if validators.check_request_method() then
        local cached_value, err = storage:get(cache_key)
        if cache:check_age(storage:ttl(cache_key)) then
            ngx.log(ngx.NOTICE, "[cache-check] the cache key exists but it was expires")
            ngx.header['X-Cache-Status'] = 'REFRESH'
            return
        end
        if cached_value and cached_value ~= ngx.null then
            ngx.log(ngx.NOTICE, "[cache-render]["..cache_key.."] setting headers")
            for header, value in pairs(cached_value.headers) do
                if string.upper(header) ~= 'CONNECTION' then
                    ngx.header[header] = value
                end
            end
            ngx.header['X-Cache-Status'] = 'HIT'
            ngx.log(ngx.NOTICE, "[cache-render]["..cache_key.."] setting response status as '"..cached_value.status.."'")
            ngx.status = cached_value.status
            ngx.log(ngx.NOTICE, "[cache-render]["..cache_key.."] setting response content")
            ngx.print(cached_value.content)
            ngx.exit(cached_value.status)
        else
            ngx.log(ngx.NOTICE, "[cache-check] the cache key '"..cache_key.."' was not found")
            ngx.header['X-Cache-Status'] = 'MISS'
        end
    else
        ngx.log(ngx.NOTICE, "[cache-check] the cache was ignored because of plugin config")
        ngx.header['X-Cache-Status'] = 'BYPASS'
    end
end

return _M
