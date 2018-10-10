local redis = require "resty.redis"
local cjson_decode = require("cjson").decode
local cjson_encode = require("cjson").encode

local _M = {}

local function json_decode(json)
    if json then
        local status, res = pcall(cjson_decode, json)
        if status then
        return res
        end
    end
end

local function json_encode(table)
    if table then
        local status, res = pcall(cjson_encode, table)
        if status then
        return res
        end
    end
end

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
    ngx.log(ngx.DEBUG, "connecting ", self.config.redis.host..':'..self.config.redis.port..'/'..self.config.redis.database)
    local ok, err = self.red:connect(self.config.redis.host, self.config.redis.port)
    if not ok then
        ngx.log(ngx.ERR, "failed to connect to Redis: ", err)
        return nil, err
    end
    local ok, err = self.red:auth(self.config.redis.password)
    if not ok then
        ngx.log(ngx.ERR, "failed to authenticate: ", err)
        return nil, err
    end
    local ok, err = self.red:select(self.config.redis.database)
    if not ok then
        ngx.log(ngx.ERR, "failed to select database: ", err)
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

function _M:set(key, value, expire_time)
    ngx.timer.at(0, function(premature)
        self:connect()
        ngx.log(ngx.DEBUG, "[storage] set key: ", key)
        local ok, err = self.red:set(key, json_encode(value))
        if not ok then
            ngx.log(ngx.ERR, "failed to set cache: ", err)
            return
        end
        self.red:expire(key, expire_time)
        self:close()
    end)
end

function _M:get(key)
    self:connect()
    ngx.log(ngx.DEBUG, "[storage] get key: ", key)
    local cached_value, err = self.red:get(key)
    if err then
        ngx.log(ngx.ERR, "failed to get cache: ", err)
        return nil, err
    end
    self:close()
    return json_decode(cached_value)
end

function _M:ttl(key)
    self:connect()
    local ttl, err  = self.red:ttl(key)
    if err then
        ngx.log(ngx.ERR, "failed to get ttl: ", err)
        return nil, err
    end
    self:close()
    return ttl
end

return _M
