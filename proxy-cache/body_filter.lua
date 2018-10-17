local Storage = require 'kong.plugins.proxy-cache.storage'
local validators = require 'kong.plugins.proxy-cache.validators'
local Cache = require 'kong.plugins.proxy-cache.cache'
local LRUCache = require "resty.lrucache"

local _M = {}

function _M.execute(config, lrucache)
    if not (validators.check_response_code(config.response_code, ngx.status) and
       validators.check_request_method()) then
        ngx.log(ngx.NOTICE, "[cache-update] the cache was not updated because of plugin config")
        return
    end
    local cached_chunks = lrucache:get(ngx.ctx.cache_key)
    local chunk, eof = ngx.arg[1], ngx.arg[2]

    local storage = Storage:new()
    local cache = Cache:new()

    storage:set_config(config)
    cache:set_config(config)

    if eof then
        cached_chunks.eof = true
        ngx.log(ngx.NOTICE, "[cache-update] response content finished")
        local body = table.concat(cached_chunks.rt_body_chunks)
        ngx.arg[1] = body
        local cache_ttl = cache:cache_ttl()
        if cache_ttl ~= nil then
            ngx.log(ngx.NOTICE, "[cache-update]["..ngx.ctx.cache_key.."]["..cache_ttl.."] updating cache")
            storage:set(ngx.ctx.cache_key, {
                headers = ngx.resp.get_headers(),
                content = body,
                status = ngx.status
            }, cache_ttl)
        else
            ngx.log(ngx.NOTICE, "[cache-update] cache TTL is undefined. So the cache was not updated")
        end
    else
        ngx.log(ngx.NOTICE, "[cache-update] getting chunk #"..cached_chunks.rt_body_chunk_number)
        cached_chunks.rt_body_chunks[ngx.ctx.rt_body_chunk_number] = chunk
        cached_chunks.rt_body_chunk_number = ngx.ctx.rt_body_chunk_number + 1
        lrucache:set(cache_key, cached_chunks)
        ngx.arg[1] = nil
    end
end

return _M
