<h3 align="center">
  kong-plugin-proxy-cache
</h3>

<p align="center">
    A Proxy Caching plugin for <a href="https://konghq.com/">Kong</a>
</p>

<p align="center">
  <a href="./LICENSE"><img src="https://img.shields.io/github/license/mashape/apistatus.svg?style=flat-square"></a>
  <a href="https://www.globo.com/"><img src="https://img.shields.io/badge/powered%20by-globo.com-blue.svg?style=flat-square"></a>
</p>

A Proxy Caching plugin for Kong makes it fast and easy to configure caching of responses and serving of those cached responses in Redis. It caches responses bases on configurable response code and request headers with the request method.

This Kong plugin adds a non-standard `X-Cache-Status` header. There are several possible values for this header:

* `MISS`: The resource was not found in cache, and the request was proxied upstream.
* `HIT`: The request was satisfied and served from cache.
* `BYPASS`: The request could not be satisfied from cache based on plugin settings.

## Getting started

Configure this plugin on a Service by making the following request:

```shell
$ curl -X POST http://kong:8001/services/{service}/plugins \
    --data "name=proxy-cache"
    --data "config.cache_ttl=300"
    --data "config.redis.host=127.0.0.1"
```

* **service**: the id or name of the Service that this plugin configuration will target.

## Configuration

Here's a list of all the settings which can be used in this plugin:

> Note: The required fields are in bold.

| Field          | Default       | Description
|----------------|---------------|----------------------------------------------------
| **response_code**  | 200, 301, 404 | Upstream response status code considered cacheable
| vary_headers   |               | Relevant headers considered for the cache key
| **cache_ttl**      | 300           | TTL, in seconds, of cache responses
| cache_control  | false         | Respect the Cache-Control behaviors
| **redis.host**     |               | Host to use for Redis connection
| **redis.port**     | 6379          | Port to use for Redis connection
| **redis.timeout**  | 2000          | Connection timeout to use for Redis connection
| redis.password |               | Password to use for Redis connection
| **redis.database** | 0             | Database to use for Redis connection

### Cache Control

When the `cache_control` is enabled by settings, Kong will respect request and response `Cache-Control` headers as defined by RFC7234, with a few notes:

* The behavior of no-cache is simplified to exclude the entity from being cached entirely.
* Secondary key calculation via Vary is not yet supported.

## Installing

### From GitHub

Navigate to kong plugins folder and execute the following commands:

```shell
$ git clone https://github.com/globocom/kong-plugin-proxy-cache
$ cd kong-plugin-proxy-cache
$ luarocks make *.rockspec
```

### From LuaRocks

Install kong-plugin-proxy-cache from [LuaRocks](https://luarocks.org/) package manager.

> **TODO**

## Contributing

Please, read the contribute guide [CONTRIBUTING](./CONTRIBUTING.md).

## License

kong-plugin-proxy-cache is [MIT licensed](./LICENSE).