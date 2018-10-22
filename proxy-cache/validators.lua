local _M = {}

function _M.check_response_code(tab, val)
    for index, value in ipairs(tab) do
        if tonumber(value) == val then
            return true
        end
    end
    return false
end

function _M.check_request_method()
    for _, value in ipairs({"GET", "HEAD"}) do
        if value == ngx.req.get_method() then
            return true
        end
    end
    return false
end

return _M
