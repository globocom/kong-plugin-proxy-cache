local Storage = require 'kong.plugins.proxy-cache.storage'
local validators = require 'kong.plugins.proxy-cache.validators'
local Cache = require 'kong.plugins.proxy-cache.cache'

local _M = {}

local storage = Storage:new()
local cache = Cache:new()

function _M.execute(config)
    storage:set_config(config)
    cache:set_config(config)

    if cache:check_no_cache() then
        ngx.log(ngx.DEBUG, "bypass: cache disabled")
        ngx.header['X-Cache-Status'] = 'BYPASS'
        return
    end

    local cache_key = cache:generate_cache_key(ngx.req, ngx.var)

    ngx.ctx.rt_body_chunks = {}
    ngx.ctx.rt_body_chunk_number = 1

    if validators.check_request_method() then
        local cached_value, err = storage:get(cache_key)
        if cached_value and cached_value ~= ngx.null then
            ngx.log(ngx.DEBUG, "hit: ", cache_key)
            for header, value in pairs(cached_value.headers) do
                if string.upper(header) ~= 'CONNECTION' then
                    ngx.header[header] = value
                end
            end
            ngx.header['X-Cache-Status'] = 'HIT'
            ngx.print(cached_value.content)
            ngx.exit(200)
        else
            ngx.log(ngx.DEBUG, "miss: ", cache_key)
            ngx.header['X-Cache-Status'] = 'MISS'
        end
    else
        ngx.log(ngx.DEBUG, "bypass: ", cache_key)
        ngx.header['X-Cache-Status'] = 'BYPASS'
        ngx.log(ngx.DEBUG, "request method is not caching: ", ngx.req.get_method())
    end
end

return _M
