VAGRANT_PROVIDER=virtualbox
# COLORS
GREEN  := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
WHITE  := $(shell tput -Txterm setaf 7)
RED    := $(shell tput -Txterm setaf 1)
RESET  := $(shell tput -Txterm sgr0)


TARGET_MAX_CHAR_NUM=20

.PHONY: help


## Show this help.
help:
	@echo 'Usage:'
	@echo '  ${YELLOW}make${RESET} ${GREEN}<target>${RESET}'
	@echo ''
	@echo 'Targets:'
	@awk '/^[a-zA-Z\-\_0-9]+:/ { \
		helpMessage = match(lastLine, /^## (.*)/); \
		if (helpMessage) { \
			helpCommand = substr($$1, 0, index($$1, ":")); \
			helpMessage = substr(lastLine, RSTART + 3, RLENGTH); \
			printf "  ${YELLOW}%-$(TARGET_MAX_CHAR_NUM)s${RESET} ${GREEN}%s${RESET}\n", helpCommand, helpMessage; \
		} \
	} \
	{ lastLine = $$0 }' $(MAKEFILE_LIST)


## build the virtual machine
create-virtualmachine:
	@echo '${GREEN}==>${RESET} Building the Virtual Machine';
	@vagrant up --provider=$(VAGRANT_PROVIDER);
	@echo '${GREEN}==>${RESET} Done.';


## delete the virtual machine
remove-virtualmachine:
	@echo '${GREEN}==>${RESET} Deleting the Virtual Machine';
	@vagrant destroy;
	@echo '${GREEN}==>${RESET} Done.';

## runs tests for Kong Plugin
test:
	@echo '${GREEN}==>${RESET} Testing Kong Plugin in Virtual Machine';
	@vagrant ssh -c "export PATH=${PATH}:/usr/local/openresty/bin && \
		cd /kong && \
		bin/busted -v -o gtest /proxy-cache-spec --pattern=*-spec.lua --defer-print";
	@echo '${GREEN}==>${RESET} Done.';

## create a new version of plugin. ex: make new_version TAG=1.0.0
new_version:
	@luarocks new_version --tag=$(TAG)
	@ls kong-plugin-proxy-cache* | grep $(TAG) | xargs luarocks pack
	@ls kong-plugin-proxy-cache* | grep -v $(TAG) | xargs rm

publish:
	@ls kong-plugin-proxy-cache-*.rockspec | xargs luarocks upload --api-key=K9q58vviH6P3g0Cw9Lv5z7fAR9E3sO7O94LeBxW3
