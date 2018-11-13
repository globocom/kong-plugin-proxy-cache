# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Changes that have landed in master but are not yet released.

## 2.0.0 - 2018-11-13
### Added
- Add Redis Sentinel support

### Changed
- Change the storage to use `pintsized/lua-resty-redis-connector` instead of `openresty/lua-resty-redis`

### Fixed
- Fix error `API disabled in the current context` when `Cache-Control` is `true`

## 1.3.3 - 2018-11-12
### Fixed
- Fix error `API disabled in the current context` when `Cache-Control` is `true`

## 1.3.2 - 2018-11-07
### Changed
- Change the default value for `cache_control` because the RFC behavior must be enabled by default

## 1.3.1 - 2018-10-31
### Fixed
- Change the body_filter should not set the `X-Cache-Status` header.

## 1.3.0 - 2018-10-30
### Added
- Add `max_idle_timeout` and `pool_size` as schema
- Add filter to remove hop-by-hop headers

### Changed
- Improves performance

## 1.2.5 - 2018-10-29
### Changed
- Improves performance

## 1.2.4 - 2018-10-22
### Changed
- Improves performance

### Fixed
- The plugin should not process the `:body_filter(config)` when `rt_body_chunks` is `nil`.

## 1.2.3 - 2018-10-22
### Changed
- Improves performance

## 1.2.2 - 2018-10-22
### Changed
- Improves performance

## 1.2.1 - 2018-10-17
### Changed
- Improves performance

## 1.2.0 - 2018-10-15
### Fixed
- The `Cache-Control` was implemented incorrectly. It was respecting the client header instead of the upstream header.

### Changed
- Change default `response_code` to `200`, `301` and `302` like the nginx default config.

### Removed
- Remove `REFRESH` from `X-Cache-Status`.
- Remove `Cache-Control: no-cache` validation on access.

## 1.1.0 - 2018-10-09
### Added
- The `ngx.host` was added to compose cache key.

### Fixed
- The cache key composition considered only the last nginx variable.

## 1.0.1 - 2018-10-04
### Added
- Add error handling on plugin exceptions.

## 1.0.0 - 2018-10-03
### Added
- This CHANGELOG file.

[1.3.2]: https://github.com/globocom/kong-plugin-proxy-cache/compare/1.3.1...1.3.2
[1.3.1]: https://github.com/globocom/kong-plugin-proxy-cache/compare/1.3.0...1.3.1
[1.3.0]: https://github.com/globocom/kong-plugin-proxy-cache/compare/1.2.5...1.3.0
[1.2.5]: https://github.com/globocom/kong-plugin-proxy-cache/compare/1.2.4...1.2.5
[1.2.4]: https://github.com/globocom/kong-plugin-proxy-cache/compare/1.2.3...1.2.4
[1.2.3]: https://github.com/globocom/kong-plugin-proxy-cache/compare/1.2.2...1.2.3
[1.2.2]: https://github.com/globocom/kong-plugin-proxy-cache/compare/1.2.1...1.2.2
[1.2.1]: https://github.com/globocom/kong-plugin-proxy-cache/compare/1.2.0...1.2.1
[1.2.0]: https://github.com/globocom/kong-plugin-proxy-cache/compare/1.1.0...1.2.0
[1.1.0]: https://github.com/globocom/kong-plugin-proxy-cache/compare/1.0.1...1.1.0
[1.0.1]: https://github.com/globocom/kong-plugin-proxy-cache/compare/1.0.0...1.0.1
