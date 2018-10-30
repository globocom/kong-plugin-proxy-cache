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
    self.red:set_timeout(self.config.redis.timeout)
    local ok, err = self.red:connect(self.config.redis.host, self.config.redis.port)
    if not ok then
        ngx.log(ngx.ERR, "failed to connect to Redis: ", err)
        return false
    end
    local pass = self.config.redis.password
    if pass ~= nil and string.len(pass) > 0 then
        local ok, err = self.red:auth(pass)
        if not ok then
            ngx.log(ngx.ERR, "failed to authenticate: ", err)
            return false
        end
    end
    local db = self.config.redis.database
    if db > 0 then
        local ok, err = self.red:select(db)
        if not ok then
            ngx.log(ngx.ERR, "failed to select database: ", err)
            return false
        end
    end
    return true
end

function _M:close()
    local ok, err = self.red:set_keepalive(10000, 1000)
    if not ok then
        ngx.log(ngx.ERR, "failed to set keepalive: ", err)
        return nil, err
    end
    return self.red
end

function _M:set(key, value, expire_time)
    local connected = self:connect()
    if not connected then
        return
    end
    local ok, err = self.red:set(key, value)
    if not ok then
        ngx.log(ngx.ERR, "failed to set cache: ", err)
        return
    end
    self.red:expire(key, expire_time)
    self:close()
end

function _M:get(key)
    local connected = self:connect()
    if not connected then
        return nil
    end
    local cached_value, err = self.red:get(key)
    if err then
        ngx.log(ngx.ERR, "failed to get cache: ", err)
        return nil, err
    end
    self:close()
    return cached_value
end

return _M
