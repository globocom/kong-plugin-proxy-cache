local Storage = require 'kong.plugins.proxy-cache.storage'
local validators = require 'kong.plugins.proxy-cache.validators'
local Cache = require 'kong.plugins.proxy-cache.cache'
local Encoder = require 'kong.plugins.proxy-cache.encoder'

local _M = {}

local function async_update_cache(config, cache_key, body)
    local headers = ngx.resp.get_headers(0, true)
    local status = ngx.status
    ngx.timer.at(0, function(premature)
        local cache = Cache:new()
        local storage = Storage:new()
        cache:set_config(config)
        storage:set_config(config)
        local cache_ttl = cache:cache_ttl()
        if cache_ttl ~= nil then
            headers["Connection"] = nil
            local cache_value = Encoder.encode(status, body, headers)
            storage:set(cache_key, cache_value, cache_ttl)
        end
    end)
end

function _M.execute(config)
    if not (validators.check_response_code(config.response_code, ngx.status) and
       validators.check_request_method()) then
        ngx.header['X-Cache-Status'] = 'BYPASS'
        return
    end
    local cache_key = ngx.ctx.cache_key
    local rt_body_chunks = ngx.ctx.rt_body_chunks
    local rt_body_chunk_number = ngx.ctx.rt_body_chunk_number
    local chunk, eof = ngx.arg[1], ngx.arg[2]

    if eof then
        local body = table.concat(rt_body_chunks)
        ngx.arg[1] = body
        return async_update_cache(config, cache_key, body)
    else
        rt_body_chunks[rt_body_chunk_number] = chunk
        rt_body_chunk_number = rt_body_chunk_number + 1
        ngx.arg[1] = nil
        ngx.ctx.rt_body_chunks = rt_body_chunks
        ngx.ctx.rt_body_chunk_number = rt_body_chunk_number
    end
end

return _M
