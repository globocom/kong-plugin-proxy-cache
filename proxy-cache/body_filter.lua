local Storage = require 'kong.plugins.proxy-cache.storage'
local validators = require 'kong.plugins.proxy-cache.validators'
local Cache = require 'kong.plugins.proxy-cache.cache'

local _M = {}

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

    local storage = Storage:new()
    local cache = Cache:new()

    storage:set_config(config)
    cache:set_config(config)

    if eof then
        local body = table.concat(rt_body_chunks)
        ngx.arg[1] = body
        local cache_ttl = cache:cache_ttl()
        if cache_ttl ~= nil then
            storage:set(cache_key, {
                headers = ngx.resp.get_headers(0, true),
                content = body,
                status = ngx.status
            }, cache_ttl)
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
