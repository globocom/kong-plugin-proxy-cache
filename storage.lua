local redis = require "resty.redis"

local _M = {}

function _M:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function _M:set_config(config)
    self.config = config or {}
end

function _M:connect()
    self.red = redis:new()
    self.red:set_timeout(1000)

    local ok, err = self.red:connect("kong-cache", 6379)
    if err then
        ngx.log(ngx.ERR, "failed to connect to Redis: ", err)
        return nil, err
    end
end

function _M:close()
    local ok, err = self.red:set_keepalive(10000, 100)
    if not ok then
        ngx.log(ngx.ERR, "failed to set keepalive: ", err)
        return nil, err
    end
    return self.red
end

function _M:set(key, value)
    ngx.timer.at(0, function(premature)
        self:connect()
        ngx.log(ngx.DEBUG, "[storage] set key: ", key)
        local ok, err = self.red:set(key, value)
        if not ok then
            ngx.log(ngx.ERR, "failed to set cache: ", err)
            return
        end
        local expire_time = self.config.cache_ttl * 60
        self.red:expire(key, expire_time)
        self:close()
    end)
end

function _M:get(key)
    self:connect()
    ngx.log(ngx.DEBUG, "[storage] get key: ", key)
    local cached_value, err = self.red:get(key)
    if err then
        ngx.log(ngx.ERR, "failed to set cache: ", err)
        return nil, err
    end
    self:close()
    return cached_value
end


return _M