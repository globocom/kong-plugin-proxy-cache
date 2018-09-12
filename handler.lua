local BasePlugin = require "kong.plugins.base_plugin"
local redis = require 'redis'
local responses = require "kong.tools.responses"
local header_filter = require "kong.plugins.response-transformer.header_transformer"
local cjson_decode = require("cjson").decode
local cjson_encode = require("cjson").encode

local ProxyCaching = BasePlugin:extend()

ProxyCaching.PRIORITY = 1005
ProxyCaching.VERSION = '0.1.0'

local is_json_body = header_filter.is_json_body
local client = {}

local function get_cache_key(method, uri)
    return ngx.md5(method .. uri)
end

local function update_cache(premature, key, value, config)
    local replies = client:pipeline(function(pipe)
        pipe:set(key, value)
    end)    
end

function ProxyCaching:new()
    ProxyCaching.super.new(self, "helloworld")
end

function ProxyCaching:init_worker()
    ProxyCaching.super.init_worker(self)
    client = redis.connect('kong-cache', 6379)
end

function ProxyCaching:access(config)
    ProxyCaching.super.access(self)

    local cache_key = get_cache_key(ngx.req.get_method(), ngx.var.uri)
    local value = client:get(cache_key)

    ngx.header["X-Cache-Key"] = cache_key

    if value ~= nil then
        ngx.status = 304
        ngx.say(value)
        ngx.exit(ngx.OK)
    end

    ngx.log(ngx.NOTICE, "cache miss")
    ngx.ctx.response_cache = {
        cache_key = cache_key
    }
end

-- function ProxyCaching:header_filter(conf)
--     ProxyCaching.super.header_filter(self)
  
--     local ctx = ngx.ctx.response_cache
--     if not ctx then
--         return
--     end
  
--     ctx.headers = ngx.resp.get_headers()
-- end

-- function ProxyCaching:body_filter(config)
--     ProxyCaching.super.body_filter(self)

--     local ctx = ngx.ctx.response_cache
--     if not ctx then
--         return
--     end
  
--     local chunk = ngx.arg[1]
--     local eof = ngx.arg[2]
    
--     local res_body = ctx and ctx.res_body or ""
--     res_body = res_body .. (chunk or "")
--     ctx.res_body = res_body
--     if eof then
--         local content = json_decode(ctx.res_body)
--         local value = { content = content, headers = ctx.headers }
--         local value_json = json_encode(value)
--         ngx.timer.at(0, red_set, ctx.cache_key, value_json, conf)
--     end
  
-- end

return ProxyCaching