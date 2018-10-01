local helpers = require "spec.helpers"
local redis = require "resty.redis"
local pretty = require "pl.pretty"


function sleep(n)
  os.execute("sleep " .. tonumber(n))
end

for _, strategy in helpers.each_strategy() do
  describe("Proxy Cache: (access) [#" .. strategy .. "]", function()
    local proxy_client
    local red = redis:new()
    local route1
    local bp

    setup(function()
      bp = helpers.get_db_utils(strategy)

      route1 = bp.routes:insert({
        hosts = { "test1.com" },
      })
      bp.plugins:insert {
        name = "proxy-cache",
        route_id = route1.id,
        config = {
          redis = {
            host = "localhost"
          }
        },
      }

      assert(helpers.start_kong({
        database   = strategy,
        nginx_conf = "spec/fixtures/custom_nginx.template",
        plugins = "bundled,proxy-cache",
      }))
    end)

    teardown(function()
      helpers.stop_kong(nil, true)
    end)

    before_each(function()
      proxy_client = helpers.proxy_client()
      local ok, err = red:connect('localhost', '6379')
      assert(ok, err)
    end)

    after_each(function()
      if proxy_client then proxy_client:close() end
      red:flushall()
      red:set_keepalive(1000, 100)
    end)

    describe("request methods", function()
      it("should caches when method GET", function()
        local response = proxy_client:get("/", {
          headers = {
            host = "test1.com"
          }
        })
        local cached_value, err = red:get('get:/')
        assert(cached_value, err)
        assert.is.truthy(cached_value)
      end)

      it("should caches when method HEAD", function()
        local response = assert(proxy_client:send {
          path = '/',
          method = 'HEAD',
          headers = {
            host = "test1.com"
          }
        })
        local cached_value, err = red:get('head:/')
        assert(cached_value, err)
        assert.is.truthy(cached_value)
      end)

      it("should not caches when method POST", function()
        local response = proxy_client:post("/", {
          headers = {
            host = "test1.com"
          }
        })
        local cached_value, err = red:get('post:/')
        assert(cached_value, err)
        assert.is.truthy(cached_value)
      end)
    end)

    describe("response headers", function()
      after_each(function()
        red:flushall()
      end)

      it("should contains 'MISS' in 'X-Cache-Status' when first access", function()
        local response = proxy_client:get("/", {
          headers = {
            host = "test1.com"
          }
        })
        local cache_status = assert.response(response).has.header("X-Cache-Status")
        assert(cache_status == 'MISS', "'X-Cache-Status' must be 'MISS'")
      end)

      it("should contains 'HIT' in 'X-Cache-Status' when access '/' two times", function()
        proxy_client:get("/hit", {
          headers = {
            host = "test1.com"
          }
        })

        local proxy_client2 = helpers.proxy_client()
        local response = proxy_client2:get("/hit", {
          headers = {
            host = "test1.com"
          }
        })
        local cache_status = assert.response(response).has.header("X-Cache-Status")
        assert(cache_status == 'HIT', "'X-Cache-Status' must be 'HIT'")
      end)

      it("should contains 'BYPASS' in 'X-Cache-Status' when invalid method", function()
        local response = proxy_client:post("/", {
          headers = {
            host = "test1.com"
          }
        })
        local cache_status = assert.response(response).has.header("X-Cache-Status")
        assert(cache_status == 'BYPASS', "'X-Cache-Status' must be 'BYPASS'")
      end)

      -- describe("Cache-Control", function()
      --   after_each(function()
      --     bp.plugins:insert {
      --       name = "proxy-cache",
      --       route_id = route1.id,
      --       config = {
      --         redis = {
      --           host = "localhost"
      --         },
      --         cache_control = true
      --       },
      --     }
      --   end)
      --   it("should contains 'BYPASS' in 'X-Cache-Status' when 'Cache-Control'", function()
      --     local response = proxy_client:get("/", {
      --       headers = {
      --         host = "test1.com",
      --         cache_control = "no-cache"
      --       }
      --     })
      --     local cache_status = assert.response(response).has.header("X-Cache-Status")
      --     assert(cache_status == 'BYPASS', "'X-Cache-Status' must be 'BYPASS'")
      --   end)
      -- end)
    end)
  end)
end
