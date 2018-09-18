local _M = {}

function _M.execute(config)
  ngx.ctx.headers = ngx.resp.get_headers()
end

return _M