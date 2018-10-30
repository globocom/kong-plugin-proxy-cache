local cjson_decode = require("cjson").decode
local cjson_encode = require("cjson").encode

local _M = {}

local function json_decode(json)
    if json then
        local status, res = pcall(cjson_decode, json)
        if status then
            return res
        end
    end
end

local function json_encode(table)
    if table then
        local status, res = pcall(cjson_encode, table)
        if status then
            return res
        end
    end
end

function _M.encode(status, content, headers)
    return json_encode({
        status = status,
        content = content,
        headers = headers
    })
end

function _M.decode(str)
    return json_decode(str)
end

return _M
