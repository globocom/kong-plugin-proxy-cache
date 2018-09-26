package = "kong-plugin-proxy-cache"
version = "0.1.0-1"
local pluginName = "proxy-cache"
source = {
   url = "git+ssh://git@github.com/globocom/kong-plugin-proxy-cache.git"
}
description = {
   detailed = "A Proxy Caching plugin for Kong",
   homepage = "https://github.com/globocom/kong-plugin-proxy-cache",
   license = "MIT"
}
build = {
   type = "builtin",
   modules = {
      ["kong.plugins."..pluginName..".access"] = pluginName.."/access.lua",
      ["kong.plugins."..pluginName..".body_filter"] = pluginName.."/body_filter.lua",
      ["kong.plugins."..pluginName..".cache"] = pluginName.."/cache.lua",
      ["kong.plugins."..pluginName..".handler"] = pluginName.."/handler.lua",
      ["kong.plugins."..pluginName..".header_filter"] = pluginName.."/header_filter.lua",
      ["kong.plugins."..pluginName..".schema"] = pluginName.."/schema.lua",
      ["kong.plugins."..pluginName..".storage"] = pluginName.."/storage.lua",
      ["kong.plugins."..pluginName..".validators"] = pluginName.."/validators.lua",
   }
}
