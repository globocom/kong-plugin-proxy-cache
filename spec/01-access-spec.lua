local helpers = require "spec.helpers"
local redis = require "resty.redis"
local pretty = require "pl.pretty"

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
        local route4 = bp.routes:insert({
            hosts = { "test-cache-control.com" },
        })
        bp.plugins:insert {
            name = "proxy-cache",
            route_id = route1.id,
            config = {
                cache_control = false,
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
            name = "request-transformer",
            route_id = route2.id,
            config = {
                add = {
                    headers = "Cache-Control:max-age=2"
                }
            },
        }
        bp.plugins:insert {
            name = "proxy-cache",
            route_id = route3.id,
            config = {
                cache_control = false,
                redis = {
                    host = "localhost"
                },
                response_code = {"404"}
            },
        }
        bp.plugins:insert {
            name = "proxy-cache",
            route_id = route4.id,
            config = {
                cache_control = true,
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
            local cache_status = response.headers["X-Cache-Status"]
            assert(cache_status == 'MISS', "'X-Cache-Status' must be 'MISS'")
        end)

        it("should contains 'HIT' in 'X-Cache-Status' when access '/' two times", function()
            proxy_client:get("/status/200", {
                headers = {
                    host = "test1.com"
                }
            })

            local proxy_client2 = helpers.proxy_client()

            local response = proxy_client2:get("/status/200", {
                headers = {
                    host = "test1.com"
                }
            })

            local cache_status = response.headers["X-Cache-Status"]
            assert(cache_status == 'HIT', "'X-Cache-Status' must be 'HIT'")
        end)

        it("should contains 'BYPASS' in 'X-Cache-Status' when invalid method", function()
            local response = proxy_client:post("/", {
                headers = {
                    host = "test1.com"
                }
            })
            local cache_status = response.headers["X-Cache-Status"]
            assert(cache_status == 'BYPASS', "'X-Cache-Status' must be 'BYPASS'")
        end)

        it("should contains 'BYPASS' in 'X-Cache-Status' when response status is 404", function()
            local response = proxy_client:get("/404", {
                headers = {
                    host = "test1.com"
                }
            })
            local cache_status = response.headers["X-Cache-Status"]
            assert(cache_status == 'BYPASS', "'X-Cache-Status' must be 'BYPASS'")
        end)

        describe("when request has Cache-Control", function()
            it("should contains 'MISS' in 'X-Cache-Status' when 'Cache-Control' not found", function()
                local response = proxy_client:get("/", {
                    headers = {
                        host = "test-cache-control.com",
                    }
                })
                local cache_status = assert.response(response).has.header("X-Cache-Status")
                assert(cache_status == 'MISS', "'X-Cache-Status' must be 'MISS'")
            end)

            it("should contains 'MISS' in 'X-Cache-Status' when cache key expires", function()
                proxy_client:get("/status/200", {
                    headers = {
                        host = "test2.com",
                    },
                })
                local proxy_client2 = helpers.proxy_client()
                ngx.sleep(3)
                local response = proxy_client2:get("/status/200", {
                    headers = {
                        host = "test2.com",
                    }
                })
                local cache_status = response.headers["X-Cache-Status"]
                assert(cache_status == 'MISS', "'X-Cache-Status' must be 'MISS'")
            end)
        end)
        describe("Response Code:", function()
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
                local cache_status = response1.headers["X-Cache-Status"]
                assert(cache_status == 'MISS', "'X-Cache-Status' must be 'MISS'")
                assert(200 == response1["status"])
                local proxy_client2 = helpers.proxy_client()
                local response2 = proxy_client2:get("/", {
                    headers = {
                        host = "test1.com"
                    }
                })

                local cache_status2 = response2.headers["X-Cache-Status"]
                assert(cache_status2 == 'HIT', "'X-Cache-Status' must be 'HIT'")
                assert(200 == response2["status"])
            end)

            it("should not cache default response code(404)", function()
                local response1 = proxy_client:get("/status/404", {
                    headers = {
                        host = "test1.com",
                        ['Cache-Control'] = "max-age=400"
                    }
                })

                local cache_status = assert.response(response1).has.header("X-Cache-Status")
                assert(cache_status == 'BYPASS', "'X-Cache-Status' must be 'BYPASS'")
                assert(404 == response1["status"], "expected 404 from status")
                local proxy_client2 = helpers.proxy_client()
                local response2 = proxy_client2:get("/status/404", {
                    headers = {
                        host = "test1.com"
                    }
                })

                local cache_status2 = assert.response(response2).has.header("X-Cache-Status")
                assert(cache_status2 == 'BYPASS', "'X-Cache-Status' must be 'BYPASS'")
                assert(404 == response2["status"], "expected 404 from status")
            end)

            it("should cache a configured response code (404)", function()
                local response1 = proxy_client:get("/status/404", {
                    headers = {
                        host = "responsecode.com",
                    }
                })

                local cache_status = assert.response(response1).has.header("X-Cache-Status")
                assert(404 == response1["status"], "expected 404 from status")
                assert(cache_status == 'MISS', "'X-Cache-Status' must be 'MISS'")
                local proxy_client2 = helpers.proxy_client()
                local response2 = proxy_client2:get("/status/404", {
                    headers = {
                        host = "responsecode.com"
                    }
                })

                local cache_status2 = assert.response(response2).has.header("X-Cache-Status")
                assert(404 == response2["status"], "expected 404 from status")
                assert(cache_status2 == 'HIT', "'X-Cache-Status' must be 'HIT'")
            end)
        end)
    end)
  end)
end
