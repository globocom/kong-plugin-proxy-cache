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
    local request_method = ngx.req.get_method()
    return request_method == 'GET' or request_method == 'HEAD'
end

return _M
