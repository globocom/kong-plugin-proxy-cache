local Validators = require("kong.plugins.proxy-cache.validators")
local schema = require("kong.plugins.proxy-cache.schema")

describe("Validators:", function()
    describe("Response Code:", function()
        setup(function()
            default_response_code = schema["fields"]["response_code"]["default"]
        end)

        it("should validate a default reponse_code", function()
            assert(Validators.check_response_code(default_response_code, 200))
            assert(Validators.check_response_code(default_response_code, 301))
            assert(Validators.check_response_code(default_response_code, 302))
        end)

        it("should not validate a reponse_code that isn't in schema default", function()
            assert(false == Validators.check_response_code(default_response_code, 500))
        end)
    end)
end)
