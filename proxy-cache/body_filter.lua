local Storage = require 'kong.plugins.proxy-cache.storage'
local validators = require 'kong.plugins.proxy-cache.validators'
local Cache = require 'kong.plugins.proxy-cache.cache'

local _M = {}

function _M.execute(config)
    local chunk, eof = ngx.arg[1], ngx.arg[2]

    local storage = Storage:new()
    local cache = Cache:new()

    storage:set_config(config)
    cache:set_config(config)

    if cache:check_no_cache() then
        return
    end
    if eof then
        local body = table.concat(ngx.ctx.rt_body_chunks)
        local cache_key = cache:generate_cache_key(ngx.req, ngx.var)
        ngx.arg[1] = body
        if validators.check_response_code(config.response_code, ngx.status) and
           validators.check_request_method() then
            local cache_ttl = cache:cache_ttl()
            if cache_ttl ~= nil then
                ngx.log(ngx.DEBUG, "updating cache: ", cache_key)
                storage:set(cache_key, {
                    headers = ngx.ctx.headers,
                    content = body,
                    status = ngx.status
                }, cache_ttl)
            end
        end
    else
        ngx.ctx.rt_body_chunks[ngx.ctx.rt_body_chunk_number] = chunk
        ngx.ctx.rt_body_chunk_number = ngx.ctx.rt_body_chunk_number + 1
        ngx.arg[1] = nil
    end
end

return _M
