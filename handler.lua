local BasePlugin = require "kong.plugins.base_plugin"
local ProxyCaching = BasePlugin:extend()

ProxyCaching.PRIORITY = 1005
ProxyCaching.VERSION = '0.1.0'

function ProxyCaching:new()
    ProxyCaching.super.new(self, "cache")
end

function ProxyCaching:init_worker()
    ProxyCaching.super.init_worker(self)
end

function ProxyCaching:access(config)
    ProxyCaching.super.access(self)

end

return ProxyCaching