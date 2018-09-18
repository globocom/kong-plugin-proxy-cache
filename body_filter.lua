local storage = require 'kong.plugins.globo-cache.storage'
local validators = require 'kong.plugins.globo-cache.validators'
local cache = require 'kong.plugins.globo-cache.cache'

local _M = {}

function _M.execute(config)
    local chunk, eof = ngx.arg[1], ngx.arg[2]

    storage:new(config)
    storage:set_config(config)

    if eof then
        local body = table.concat(ngx.ctx.rt_body_chunks)
        local cache_key = cache.generate_cache_key(config.vary_headers)
        ngx.arg[1] = body
        if validators.check_response_code(config.response_code, ngx.status) and
           validators.check_request_method(config.request_method) then
            ngx.log(ngx.DEBUG, "updating cache: ", cache_key)
            storage:set(cache_key, {
                headers = ngx.ctx.headers,
                content = body
            })
        end
    else
        ngx.ctx.rt_body_chunks[ngx.ctx.rt_body_chunk_number] = chunk
        ngx.ctx.rt_body_chunk_number = ngx.ctx.rt_body_chunk_number + 1
        ngx.arg[1] = nil
    end
end

return _M