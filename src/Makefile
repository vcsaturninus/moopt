SRC:=src
TESTS:=tests
OUT:=out
LUA:=lua

all: clean test compile

clean:
	@rm -rf $(OUT)/*

test:
	@$(LUA) $(TESTS)/moopt_tests.lua

compile:
	@cp $(SRC)/moopt.lua $(OUT)/
