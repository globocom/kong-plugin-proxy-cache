local redis_connector = require("resty.redis.connector")

local _M = {}

function _M:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function _M:set_config(config)
    local redis_config = {
        host = config.redis.host,
        port = config.redis.port,
        password = config.redis.password,
        db = config.redis.database,
        read_timeout = config.redis.timeout,
        keepalive_timeout = config.redis.max_idle_timeout,
        keepalive_poolsize = config.redis.pool_size
    }
    local sentinel_master_name = config.redis.sentinel_master_name
    if sentinel_master_name ~= nil and string.len(sentinel_master_name) > 0 then
        redis_config.master_name = sentinel_master_name
        redis_config.role = config.redis.sentinel_role
        local sentinels = config.redis.sentinel_addresses
        if sentinels then
            redis_config.sentinels = {}
            for _, sentinel in ipairs(sentinels) do
                local sentinel_host, sentinel_port = string.match(sentinel, "(.*)[:](%d*)")
                redis_config.sentinels[#redis_config.sentinels+1] = {
                    host = sentinel_host,
                    port = sentinel_port
                }
            end
        end
    end
    self.connector = redis_connector.new(redis_config)
end

function _M:connect()
    local red, err = self.connector:connect()
    if red == nil then
        ngx.log(ngx.ERR, "failed to connect to Redis: ", err)
        return false
    end
    self.red = red
    return true
end

function _M:close()
    local ok, err = self.connector:set_keepalive(self.red)
    if not ok then
        ngx.log(ngx.ERR, "failed to set keepalive: ", err)
        return false
    end
    return true
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
