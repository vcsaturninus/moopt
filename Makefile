TESTS:=tests/tests.lua
LICENSE:=LICENSE

export LUA_PATH:=./src/?.lua;./aux/?.lua;$(LUA_PATH)

all:
	@echo "Running tests ... "
	@./tests/tests.lua

tests: all

.PHONY: license

license:
	@cat $(LICENSE)

