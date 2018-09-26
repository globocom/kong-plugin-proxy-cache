local helpers = require "spec.helpers"

for _, strategy in helpers.each_strategy() do
  describe("[proxy-cache][access][#" .. strategy .. "]", function()
    local proxy_client

    setup(function()
      local bp = helpers.get_db_utils(strategy)

      local route1 = bp.routes:insert({
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
    end)

    after_each(function()
      if proxy_client then proxy_client:close() end
    end)

    describe("request", function()
      it("gets a 'hello-world' header", function()
        local response = proxy_client:get("/request", {
          headers = {
            host = "test1.com"
          }
        })
        assert.res_status(200, response)
      end)
    end)
  end)
end