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

    setup(function()
        local bp = helpers.get_db_utils(strategy)
        local route1 = bp.routes:insert({
            hosts = { "test1.com" },
        })
        local route2 = bp.routes:insert({
            hosts = { "test2.com" },
        })
        local route3 = bp.routes:insert({
            hosts = { "responsecode.com" },
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
        bp.plugins:insert {
            name = "proxy-cache",
            route_id = route2.id,
            config = {
                cache_control = true,
                redis = {
                    host = "localhost"
                }
            },
        }
        bp.plugins:insert {
            name = "proxy-cache",
            route_id = route3.id,
            config = {
                cache_control = true,
                redis = {
                    host = "localhost"
                },
                response_code = {"404"}
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
        sleep(0.5)
        local response = proxy_client2:get("/hit", {
          headers = {
            host = "test1.com"
          }
        })

        local cache_status = assert.response(response).has.header("X-Cache-Status")
        assert(cache_status == 'MISS', "'X-Cache-Status' must be 'MISS'")
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

      it("should return 404 when access two times a invalid route", function()
        local response = proxy_client:get("/404", {
          headers = {
            host = "test1.com"
          }
        })

        local cache_status = response.headers["X-Cache-Status"]
        assert(cache_status == 'MISS', "'X-Cache-Status' must be 'MISS'")
        assert(response.status == 404)

        local proxy_client2 = helpers.proxy_client()
        sleep(1)
        local response2 = proxy_client2:get("/404", {
          headers = {
            host = "test1.com"
          }
        })

        local cache_status = response2.headers["X-Cache-Status"]
        assert(cache_status == 'MISS', "'X-Cache-Status' must be 'MISS'")
        assert(response2.status == 404)
      end)

      describe("when request has Cache-Control", function()
        it("should contains 'REFRESH' in 'X-Cache-Status' when 'Cache-Control' is 'no-cache'", function()
            local response = proxy_client:get("/", {
                headers = {
                    host = "test2.com",
                    ['Cache-Control'] = "no-cache"
                }
            })
            local cache_status = assert.response(response).has.header("X-Cache-Status")
            assert(cache_status == 'REFRESH', "'X-Cache-Status' must be 'REFRESH'")
        end)

        it("should contains 'MISS' in 'X-Cache-Status' when 'Cache-Control' not found", function()
            local response = proxy_client:get("/", {
                headers = {
                    host = "test2.com",
                    ['Cache-Control'] = "max-age=400"
                }
            })
            local cache_status = assert.response(response).has.header("X-Cache-Status")
            assert(cache_status == 'MISS', "'X-Cache-Status' must be 'MISS'")
        end)

        it("should contains 'MISS' in 'X-Cache-Status' when 'max-age' expires", function()
            proxy_client:get("/", {
                headers = {
                    host = "test2.com",
                    ['Cache-Control'] = "max-age=2"
                }
            })
            local proxy_client2 = helpers.proxy_client()
            sleep(3)
            local response = proxy_client2:get("/", {
                headers = {
                    host = "test2.com",
                    ['Cache-Control'] = "max-age=2"
                }
            })
            local cache_status = assert.response(response).has.header("X-Cache-Status")
            assert(cache_status == 'MISS', "'X-Cache-Status' must be 'MISS'")
        end)

        it("should contains 'REFRESH' in 'X-Cache-Status' when 'max-age' not found", function()
            local response = proxy_client:get("/", {
                headers = {
                    host = "test2.com"
                }
            })
            local cache_status = assert.response(response).has.header("X-Cache-Status")
            assert(cache_status == 'REFRESH', "'X-Cache-Status' must be 'REFRESH'")
        end)
      end)
      describe("Reponse Code:", function()
        after_each(function()
          red:flushall()
        end)

        it("should cache default response codes(200)", function()
          local response1 = proxy_client:get("/", {
            headers = {
                  host = "test1.com",
                  ['Cache-Control'] = "max-age=400"
              }
          })
          local cache_status = assert.response(response1).has.header("X-Cache-Status")
          assert(cache_status == 'MISS', "'X-Cache-Status' must be 'MISS'")
          assert(200 == response1["status"])

          sleep(0.5)
          local proxy_client2 = helpers.proxy_client()
          local response2 = proxy_client2:get("/", {
            headers = {
              host = "test1.com"
            }
          })

          local cache_status2 = assert.response(response2).has.header("X-Cache-Status")
          assert(cache_status2 == 'HIT', "'X-Cache-Status' must be 'HIT'")
          assert(200 == response2["status"])
        end)

        it("should not cache default response code(404)", function()
          local response1 = proxy_client:get("/notfound", {
            headers = {
                  host = "test1.com",
                  ['Cache-Control'] = "max-age=400"
              }
          })

          local cache_status = assert.response(response1).has.header("X-Cache-Status")
          assert(cache_status == 'MISS', "'X-Cache-Status' must be 'MISS'")
          assert(404 == response1["status"], "expected 404 from status")

          sleep(0.5)
          local proxy_client2 = helpers.proxy_client()
          local response2 = proxy_client2:get("/notfound", {
            headers = {
              host = "test1.com"
            }
          })

          local cache_status2 = assert.response(response2).has.header("X-Cache-Status")
          assert(cache_status2 == 'MISS', "'X-Cache-Status' must be 'MISS'")
          assert(404 == response2["status"], "expected 404 from status")
        end)

        it("should cache a configured response code (404)", function()
          local response1 = proxy_client:get("/notfound", {
            headers = {
                  host = "responsecode.com",
              }
          })

          local cache_status = assert.response(response1).has.header("X-Cache-Status")
          assert(cache_status == 'MISS', "'X-Cache-Status' must be 'MISS'")
          assert(404 == response1["status"], "expected 404 from status")

          sleep(0.5)
          local proxy_client2 = helpers.proxy_client()
          local response2 = proxy_client2:get("/notfound", {
            headers = {
              host = "responsecode.com"
            }
          })

          local cache_status2 = assert.response(response2).has.header("X-Cache-Status")
          assert(cache_status2 == 'HIT', "'X-Cache-Status' must be 'HIT'")
          assert(404 == response2["status"], "expected 404 from status")
        end)
      end)
    end)
  end)
end
