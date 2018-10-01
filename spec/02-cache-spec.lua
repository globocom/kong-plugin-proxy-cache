local Cache = require("kong.plugins.proxy-cache.cache")

describe("Proxy Cache: (cache) ", function()
  describe("generate_cache_key", function()
    it("should return cache key with 'request_uri'", function()
      -- arrange
      local request = {
        get_method = function()
          return 'GET'
        end
      }
      local nginx_variables = {
        request_uri = "request_uri"
      }
      local cache = Cache:new()
      cache:set_config()
      -- act
      local cache_key = cache:generate_cache_key(request, nginx_variables)
      -- assert
      assert(string.match(cache_key, "request_uri"), "'request_uri' not found in "..cache_key)
    end)

    it("should return cache key with 'request_method'", function()
      -- arrange
      local request = {
        get_method = function()
          return 'GET'
        end
      }
      local nginx_variables = {
        request_uri = "request_uri"
      }
      local cache = Cache:new()
      cache:set_config()
      -- act
      local cache_key = cache:generate_cache_key(request, nginx_variables)
      -- assert
      assert(string.match(cache_key, "get"), "'request_method' not found in "..cache_key)
    end)

    it("should return cache key with header 'Authorization'", function()
      -- arrange
      local request = {
        get_method = function()
          return 'GET'
        end,
        get_headers = function()
          return {
            Authorization = 'basic'
          }
        end
      }
      local nginx_variables = {
        request_uri = "request_uri"
      }
      local config = {
        vary_headers = {"Authorization"}
      }
      local cache = Cache:new()
      cache:set_config(config)
      -- act
      local cache_key = cache:generate_cache_key(request, nginx_variables)
      -- assert
      assert(string.match(cache_key, "authorization=basic"), "header 'Authorization' not found in "..cache_key)
    end)
  end)
end)
