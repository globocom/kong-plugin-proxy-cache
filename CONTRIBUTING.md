# Contributing

Want to contribute to kong-plugin-proxy-cache? There are a few things you need to know. We wrote this contribution guide to help you get started.

## Semantic Versioning

kong-plugin-proxy-cache follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html). We release patch versions for bugfixes, minor versions for new features, and major versions for any breaking changes.

Every significant change is documented in the changelog file.

## Sending a Pull Request

The core team is monitoring for pull requests. We will review your pull request and either merge it, request changes to it, or close it with an explanation. For API changes we may need to fix our internal uses at Globo.com, which could cause some delay. We’ll do our best to provide updates and feedback throughout the process.

**Before submitting a pull request**, please make sure the following is done:

1. Fork the repository and create your branch from master.
2. Run `make create-virtualmachine` in the repository root.
3. If you’ve fixed a bug or added code that should be tested, add tests!

### Contribution Prerequisites

* You have [Vagrant](https://www.vagrantup.com/) installed.
* You have [VirtualBox](https://www.virtualbox.org/) installed.
* You are familiar with Git.

### Development Workflow

After cloning kong-plugin-proxy-cache, run `make create-virtualmachine` to build the virtual machine. Then, you can run several commands:

* `make help` show the help
* `make test` runs tests for Kong Plugin
* `make create-virtualmachine` build the virtual machine
* `make remove-virtualmachine` delete the virtual machine

## License

By contributing to kong-plugin-proxy-cache, you agree that your contributions will be licensed under its [MIT license](./LICENSE).
