package = "kong-plugin-proxy-cache"
version = "1.1.0-1"
source = {
   url = "git+ssh://git@github.com/globocom/kong-plugin-proxy-cache.git",
   tag = "1.1.0"
}
description = {
   detailed = "A Proxy Caching plugin for Kong",
   homepage = "https://github.com/globocom/kong-plugin-proxy-cache",
   license = "MIT"
}
build = {
   type = "builtin",
   modules = {
      ["kong.plugins.proxy-cache.access"] = "proxy-cache/access.lua",
      ["kong.plugins.proxy-cache.body_filter"] = "proxy-cache/body_filter.lua",
      ["kong.plugins.proxy-cache.cache"] = "proxy-cache/cache.lua",
      ["kong.plugins.proxy-cache.handler"] = "proxy-cache/handler.lua",
      ["kong.plugins.proxy-cache.header_filter"] = "proxy-cache/header_filter.lua",
      ["kong.plugins.proxy-cache.schema"] = "proxy-cache/schema.lua",
      ["kong.plugins.proxy-cache.storage"] = "proxy-cache/storage.lua",
      ["kong.plugins.proxy-cache.validators"] = "proxy-cache/validators.lua"
   }
}
