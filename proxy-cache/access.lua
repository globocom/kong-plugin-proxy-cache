local Storage = require 'kong.plugins.proxy-cache.storage'
local validators = require 'kong.plugins.proxy-cache.validators'
local Cache = require 'kong.plugins.proxy-cache.cache'

local _M = {}

local function render_from_cache(cache_key, cached_value)
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
end

function _M.execute(config)
    ngx.ctx.rt_body_chunks = {}
    ngx.ctx.rt_body_chunk_number = 1

    local storage = Storage:new()
    local cache = Cache:new()
    
    storage:set_config(config)
    cache:set_config(config)

    if not validators.check_request_method() then
        ngx.log(ngx.NOTICE, "[cache-check] the cache was ignored because of plugin config")
        ngx.header['X-Cache-Status'] = 'BYPASS'
        return
    end
    
    ngx.ctx.cache_key = cache:generate_cache_key(ngx.req, ngx.var)
    local cached_value_ttl = storage:ttl(ngx.ctx.cache_key)
    if cached_value_ttl == -2 then
        ngx.log(ngx.NOTICE, "[cache-check] the cache key '"..ngx.ctx.cache_key.."' was not found")
        ngx.header['X-Cache-Status'] = 'MISS'
        return
    end
    local cached_value, err = storage:get(ngx.ctx.cache_key)
    return render_from_cache(ngx.ctx.cache_key, cached_value)
end

return _M
