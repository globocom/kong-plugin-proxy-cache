local Storage = require 'kong.plugins.proxy-cache.storage'
local validators = require 'kong.plugins.proxy-cache.validators'
local Cache = require 'kong.plugins.proxy-cache.cache'
local Encoder = require 'kong.plugins.proxy-cache.encoder'

local _M = {}

local function render_from_cache(cache_key, cached_value)
    local response = Encoder.decode(cached_value)
    if response.headers then
        for header, value in pairs(response.headers) do
            ngx.header[header] = value
        end
    end
    ngx.header['X-Cache-Status'] = 'HIT'
    ngx.status = response.status
    ngx.print(response.content)
    ngx.exit(response.status)
end

function _M.execute(config)
    local storage = Storage:new()
    local cache = Cache:new()
    storage:set_config(config)
    cache:set_config(config)

    if not validators.check_request_method() then
        ngx.header['X-Cache-Status'] = 'BYPASS'
        return
    end
    local cache_key = cache:generate_cache_key(ngx.req, ngx.var)
    local cached_value, err = storage:get(cache_key)
    if not (cached_value and cached_value ~= ngx.null) then
        ngx.header['X-Cache-Status'] = 'MISS'
        ngx.ctx.cache_key = cache_key
        ngx.ctx.rt_body_chunks = {}
        ngx.ctx.rt_body_chunk_number = 1
        return
    end
    return render_from_cache(cache_key, cached_value)
end

return _M
