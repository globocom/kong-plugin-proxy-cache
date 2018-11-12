local Storage = require 'kong.plugins.proxy-cache.storage'
local validators = require 'kong.plugins.proxy-cache.validators'
local Cache = require 'kong.plugins.proxy-cache.cache'
local Encoder = require 'kong.plugins.proxy-cache.encoder'

local _M = {}

local function filter_headers(headers)
    -- remove hop-by-hop headers
    headers["Connection"] = nil
    headers["connection"] = nil
    headers["Keep-Alive"] = nil
    headers["keep-alive"] = nil
    headers["Public"] = nil
    headers["public"] = nil
    headers["Proxy-Authenticate"] = nil
    headers["proxy-authenticate"] = nil
    headers["Transfer-Encoding"] = nil
    headers["transfer-encoding"] = nil
    headers["Upgrade"] = nil
    headers["upgrade"] = nil
    headers["Via"] = nil
    headers["via"] = nil
    -- remove kong custom headers
    headers["X-Kong-Upstream-Latency"] = nil
    headers["X-Kong-Proxy-Latency"] = nil
    -- remove plugin custom headers
    headers["X-Cache-Status"] = nil
    return headers
end

local function async_update_cache(config, cache_key, body)
    local cache = Cache:new()
    cache:set_config(config)

    local cache_ttl = cache:cache_ttl()
    local headers = ngx.resp.get_headers(0, true)
    local status = ngx.status
    ngx.timer.at(0, function(premature)
        local storage = Storage:new()
        storage:set_config(config)
        if cache_ttl ~= nil then
            local cache_value = Encoder.encode(status, body, filter_headers(headers))
            storage:set(cache_key, cache_value, cache_ttl)
        end
    end)
end

function _M.execute(config)
    local cache_key = ngx.ctx.cache_key
    local rt_body_chunks = ngx.ctx.rt_body_chunks
    local rt_body_chunk_number = ngx.ctx.rt_body_chunk_number
    local chunk, eof = ngx.arg[1], ngx.arg[2]

    if eof then
        local body = table.concat(rt_body_chunks)
        ngx.arg[1] = body
        if validators.check_response_code(config.response_code, ngx.status) and
           validators.check_request_method() then
            return async_update_cache(config, cache_key, body)
        end
    else
        rt_body_chunks[rt_body_chunk_number] = chunk
        rt_body_chunk_number = rt_body_chunk_number + 1
        ngx.arg[1] = nil
        ngx.ctx.rt_body_chunks = rt_body_chunks
        ngx.ctx.rt_body_chunk_number = rt_body_chunk_number
    end
end

return _M
