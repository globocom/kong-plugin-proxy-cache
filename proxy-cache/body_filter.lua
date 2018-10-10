local Storage = require 'kong.plugins.proxy-cache.storage'
local validators = require 'kong.plugins.proxy-cache.validators'
local Cache = require 'kong.plugins.proxy-cache.cache'

local _M = {}

local function update_cache(cache_key, body)
    ngx.arg[1] = body
    if not (validators.check_response_code(config.response_code, ngx.status) and
       validators.check_request_method()) then
        ngx.log(ngx.NOTICE, "[cache-update] the cache was not updated because of plugin config")
        return
    end
    local cache_ttl = cache:cache_ttl()
    if cache_ttl ~= nil then
        ngx.log(ngx.NOTICE, "[cache-update]["..cache_key.."]["..cache_ttl.."] updating cache")
        storage:set(cache_key, {
            headers = ngx.ctx.headers,
            content = body,
            status = ngx.status
        }, cache_ttl)
    else
        ngx.log(ngx.NOTICE, "[cache-update] cache TTL is undefined. So the cache was not updated")
    end
end

function _M.execute(config)
    local chunk, eof = ngx.arg[1], ngx.arg[2]

    local storage = Storage:new()
    local cache = Cache:new()

    storage:set_config(config)
    cache:set_config(config)

    if cache:check_no_cache() then
        ngx.log(ngx.NOTICE, "[cache-update] cache-control: no-cache")
        return
    end
    if eof then
        ngx.log(ngx.NOTICE, "[cache-update] response content finished")
        local body = table.concat(ngx.ctx.rt_body_chunks)
        return update_cache(ngx.ctx.cache_key, body)
    else
        ngx.log(ngx.NOTICE, "[cache-update] getting chunk #"..ngx.ctx.rt_body_chunk_number)
        ngx.ctx.rt_body_chunks[ngx.ctx.rt_body_chunk_number] = chunk
        ngx.ctx.rt_body_chunk_number = ngx.ctx.rt_body_chunk_number + 1
        ngx.arg[1] = nil
    end
end

return _M
