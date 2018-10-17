# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Changes that have landed in master but are not yet released.

## 1.2.1 - 2018-10-17
### Changed
- Improves performance

## 1.2.0 - 2018-10-15
### Fixed
- `Cache-Control` was implemented incorrectly. It was respecting the client header instead of the upstream header.

### Changed
- Change default `response_code` to `200`, `301` and `302` like the nginx default config.

### Removed
- `REFRESH` from `X-Cache-Status`.
- `Cache-Control: no-cache` validation on access.

## 1.1.0 - 2018-10-09
### Added
- `ngx.host` was added to compose cache key.

### Fixed
- The cache key composition considered only the last nginx variable.

## 1.0.1 - 2018-10-04
### Changed
- Error handling on plugin exceptions.

## 1.0.0 - 2018-10-03
### Added
- This CHANGELOG file.

[1.1.0]: https://github.com/globocom/kong-plugin-proxy-cache/compare/1.0.1...1.1.0
[1.0.1]: https://github.com/globocom/kong-plugin-proxy-cache/compare/1.0.0...1.0.1
