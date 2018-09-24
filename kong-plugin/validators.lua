local _M = {}

function _M.check_response_code(tab, val)
    for index, value in ipairs(tab) do
        if tonumber(value) == val then
            ngx.log(ngx.DEBUG, 'response code is caching: ', val)
            return true
        end
    end
    ngx.log(ngx.DEBUG, 'response code is not caching')
    return false
end

function _M.check_request_method()
    for _, value in ipairs({"GET", "HEAD"}) do
        if value == ngx.req.get_method() then
            ngx.log(ngx.DEBUG, 'request method is caching: ', value)
            return true
        end
    end
    ngx.log(ngx.DEBUG, 'request method is not caching')
    return false
end

return _M