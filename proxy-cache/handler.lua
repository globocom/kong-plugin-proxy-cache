local BasePlugin = require "kong.plugins.base_plugin"
local access = require 'kong.plugins.proxy-cache.access'
local body_filter = require 'kong.plugins.proxy-cache.body_filter'
local header_filter = require 'kong.plugins.proxy-cache.header_filter'

local ProxyCaching = BasePlugin:extend()

ProxyCaching.PRIORITY = 1006
ProxyCaching.VERSION = '2.0.0'

function ProxyCaching:new()
    ProxyCaching.super.new(self, "proxy-cache")
end

function ProxyCaching:init_worker()
    ProxyCaching.super.init_worker(self)
end

function ProxyCaching:access(config)
    ProxyCaching.super.access(self)
    local ok, err = pcall(access.execute, config)
    if not ok then
        ngx.log(ngx.CRIT, err)
    end
end

function ProxyCaching:header_filter(config)
    ProxyCaching.super.header_filter(self)
    local ok, err = pcall(header_filter.execute, config)
    if not ok then
        ngx.log(ngx.CRIT, err)
    end
end

function ProxyCaching:body_filter(config)
    ProxyCaching.super.body_filter(self)
    local rt_body_chunks = ngx.ctx.rt_body_chunks
    local is_miss =  ngx.header['X-Cache-Status'] == 'MISS'
    if rt_body_chunks and is_miss then
        local ok, err = pcall(body_filter.execute, config)
        if not ok then
            ngx.log(ngx.CRIT, err)
        end
    end
end

return ProxyCaching
