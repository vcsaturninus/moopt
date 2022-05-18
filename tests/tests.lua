#!/usr/bin/lua5.3

package.path = package.path .. ";../src/?.lua"

local moopt = require("moopt")
local utils = require("mutils")
local fails = 0

-- compare two arrays of arrays
function compare_arrays(a, b)
    if not a or not b then return false end

    for k,v in pairs(a) do
        if v ~= b[k] then return false end
    end

    for k,v in pairs(b) do
        if v ~= a[k] then return false end
    end
    return true
end

function compare(a,b)
    local dbg = os.getenv("DEBUG_MODE") and true or false 
    if dbg then
        print(utils.ptable(a, 2, "expected"))
        print(utils.ptable(b, 2, "actual"))
    end

    for k,v in pairs(a) do 
        if not (compare_arrays(v, b[k])) then 
            if dbg then 
                print(string.format("\t --> difference found at index %s ", k))
            end
            return false 
        end
    end

    return true
end

function test(optstring, argv, expected, longs)
    local actual = moopt.test_getopt(0, argv, optstring, longs)
    local passed = compare(expected, actual)

    local args = "["
    for _,v in ipairs(argv) do
        args = args .. string.format("\"%s\", ", v)
    end
    
    args = args:sub(1,-3)
    args = args .. "]"

    print(string.format(" | %s\t'%s' ~~ %s ", passed and "passed" or "FAILED!!!!!", optstring, args))
    if not passed then fails = fails+1 end
end
-------------------------------------------------
-------------------------------------------------
-------------------------------------------------
--
local t1argv = {"-abarg","-c", "-"}
local t1optstring = "+ab::c:"
local t1exp = {
    {o = 'a', oi = 1, oa = nil, oo = nil},
    {o = 'b', oi = 2, oa = "arg", oo = nil},
    {o = 'c', oi = 4, oa = '-', oo = nil},
    {o = -1, oi = 4, oa = nil, oo = nil}
}

local t2argv = {"-ab", "-carg", "-c"} 
local t2optstring = "+ab:c::"
local t2exp = {
    {o = 'a', oi =  1, oa = nil, oo = nil},
    {o = ':', oi =  2, oa = nil, oo = 'b'},
    {o = 'c', oi =  3, oa = 'arg', oo =  nil},
    {o = 'c', oi =  4, oa = nil, oo = nil},
    {o = -1, oi = 4, oa = nil, oo = nil}
}

local t3argv = {"-a", "what", "-barg", "-b", "-c", "arg", "-a", "--", "arg"}
local t3optstring = "+a:b::c:"
local t3exp = {
    {o = 'a', oi = 3, oa = 'what', oo = nil},
    {o = 'b', oi = 4, oa = "arg", oo = nil},
    {o = 'b', oi = 5, oa = nil, oo = nil},
    {o = 'c', oi = 7, oa = 'arg', oo = nil},
    {o = ':', oi = 8, oa = nil, oo = 'a'},
    {o = -1, oi = 9, oa = nil, oo = nil}
}

local t4argv = {"-abcdef", "--", "arg"}
local t4optstring = "?abcdef:"
local t4exp = {
    {o = 'a', oi = 1, oa = nil, oo = nil},
    {o = 'b', oi = 1, oa = nil, oo = nil},
    {o = 'c', oi = 1, oa = nil, oo = nil},
    {o = 'd', oi = 1, oa = nil, oo = nil},
    {o = 'e', oi = 1, oa = nil, oo = nil},
    {o = '?', oi = 2, oa = nil, oo = 'f'},
    {o = -1, oi = 3, oa = nil, oo = nil}
}

local t5argv = {"--abarg","-c", "-", "-c", "--", "arg"}
local t5optstring = "+a-bc::"
local t5exp = {
    {o = '?', oi = 1, oa = nil, oo = '-'},
    {o = 'a', oi = 1, oa = nil, oo = nil},
    {o = 'b', oi = 1, oa = nil, oo = nil},
    {o = 'a', oi = 1, oa = nil, oo = nil},
    {o = '?', oi = 1, oa = nil, oo = 'r'},
    {o = '?', oi = 2, oa = nil, oo = 'g'},
    {o = 'c', oi = 4, oa = '-', oo = nil},
    {o = 'c', oi = 5, oa = nil, oo = nil},
    {o = -1, oi = 6, oa = nil, oo = nil}
}

local t6argv = {"-157ag", "--", "-f"}
local t6optstring = ":135ag:f::"
local t6exp = {
    {o = '1', oi = 1, oa = nil, oo = nil},
    {o = '5', oi = 1, oa = nil, oo = nil},
    {o = '?', oi = 1, oa = nil, oo = '7'},
    {o = 'a', oi = 1, oa = nil, oo = nil},
    {o = ':', oi = 2, oa = nil, oo = 'g'},
    {o = -1, oi = 3, oa = nil, oo = nil}
}

local t7argv = {"-abc", "-er", "-g"}
local t7optstring = ":"
local t7exp = {
    {o = '?', oi = 1, oa = nil, oo = 'a'},
    {o = '?', oi = 1, oa = nil, oo = 'b'},
    {o = '?', oi = 2, oa = nil, oo = 'c'},
    {o = '?', oi = 2, oa = nil, oo = 'e'},
    {o = '?', oi = 3, oa = nil, oo = 'r'},
    {o = '?', oi = 4, oa = nil, oo = 'g'},
    {o = -1, oi = 4, oa = nil, oo = nil}
}

local t8argv = {"some"}
local t8optstring = ":"
local t8exp = {
    {o = -1, oi = 1, oa = nil, oo = nil}
}

local t9argv = {}
local t9optstring = ":abc:"
local t9exp = {
    {o = -1, oi = 1, oa = nil, oo = nil}
}

-----------------------------------------
-----------------------------------------
-- getopt_long tests
-----------------------------------------
-----------------------------------------

-- test longs and shorts
local t10argv = {"--verbose", "--path", "-157ag", "--test", "--two", "myarg", "--flag", "--", "-f"}
local t10optstring = ":135ag:f::"
local t10longs = {
    test = {has_arg=0, val = 'x'},
    two = {has_arg=2, val = 'y'},
    flag = {has_arg=0, val = 'h'},
    path = {has_arg=1, val = 'p'},
    verbose = {has_arg=0, val = 'v'}
}

local t10exp = {
    {o = 'v', oi = 2, oa = nil, oo = nil},
    {o = ':', oi=3, oa=nil, oo='path'},
    {o = '1', oi = 3, oa = nil, oo = nil},
    {o = '5', oi = 3, oa = nil, oo = nil},
    {o = '?', oi = 3, oa = nil, oo = '7'},
    {o = 'a', oi = 3, oa = nil, oo = nil},
    {o = ':', oi = 4, oa = nil, oo = 'g'},
    {o = 'x', oi = 5, oa = nil, oo = nil},
    {o = 'y', oi = 7, oa = 'myarg', oo = nil},
    {o = 'h', oi = 8, oa = nil, oo = nil},
    {o = -1, oi = 9, oa = nil, oo = nil}
}

-- test only valid shorts with getopt_long
local t11argv = {"-vvv", "-p", "mypath", "-p", "--path", "myarg"}
local t11optstring = ":vp:"
local t11longs = {
}

local t11exp = {
    {o = 'v', oi = 1, oa = nil, oo = nil},
    {o = 'v', oi = 1, oa = nil, oo = nil},
    {o = 'v', oi = 2, oa = nil, oo = nil},
    {o = 'p', oi = 4, oa = 'mypath', oo = nil},
    {o = ':', oi = 5, oa = nil, oo = 'p'},
    {o = '?', oi = 6, oa = nil, oo = '--path'},
    {o = -1, oi = 6, oa = nil, oo = nil}
}

-- no arguments
local t12argv = {""}
local t12optstring = ":135ag:f::"
local t12longs = {
    test = {has_arg=0, val = 'x'},
    two = {has_arg=2, val = 'y'},
    flag = {has_arg=0, val = 'h'},
    path = {has_arg=1, val = 'p'},
    verbose = {has_arg=0, val = 'v'}
}

local t12exp = {
    {o = -1, oi = 1, oa = nil, oo = nil}
}

-- only long options that expect a param
local t13argv = {"--verbose", "1", "--11", "true", "--flag1", "--flag2", "--flag3", "--", "-f"}
local t13optstring = "?135ag:f::"
local t13longs = {
    verbose = {has_arg=1, val = 'v'},
    ["11"] = {has_arg=1, val = 's'},
    flag1 = {has_arg=1, val = 'f'},
    flag2 = {has_arg=2, val = 'j'},
    flag3 = {has_arg=1, val = 'l'}
}

local t13exp = {
    {o = 'v', oi = 3, oa = '1', oo = nil},
    {o = 's', oi=5, oa='true', oo=nil},
    {o = '?', oi = 6, oa = nil, oo = 'flag1'},
    {o = 'j', oi = 7, oa = nil, oo = nil},
    {o = '?', oi = 8, oa = nil, oo = 'flag3'},
    {o = -1, oi = 9, oa = nil, oo = nil}
}

-- test only unknown longs
local t14argv = {"--verbose", "--path", "--test", "--two", "myarg"}
local t14optstring = ":"
local t14longs = {
}

local t14exp = {
    {o = '?', oi = 2, oa = nil, oo = '--verbose'},
    {o = '?', oi = 3, oa = nil, oo = '--path'},
    {o = '?', oi = 4, oa = nil, oo = '--test'},
    {o = '?', oi = 5, oa = nil, oo = '--two'},
    {o = -1, oi = 5, oa = nil, oo = nil}
}

-- test shorts and longs that only optionally expects arguments, and do NOT pass any arguments
local t15argv = {"--verbose", "-v", "--path", "-p", "-tlm", "--two", "--three"}
local t15optstring = "+v::p::tlm::"
local t15longs = {
    verbose = {has_arg=0, val = 'x'},
    path = {has_arg=2, val = 'y'},
    two = {has_arg=2, val = 'h'},
    three = {has_arg=2, val = 'p'},
}

local t15exp = {
    {o = 'x', oi = 2, oa = nil, oo = nil},
    {o = 'v', oi=3, oa=nil, oo=nil},
    {o = 'y', oi = 4, oa = nil, oo = nil},
    {o = 'p', oi = 5, oa = nil, oo = nil},
    {o = 't', oi = 5, oa = nil, oo = nil},
    {o = 'l', oi = 5, oa = nil, oo = nil},
    {o = 'm', oi = 6, oa = nil, oo = nil},
    {o = 'h', oi = 7, oa = nil, oo = nil},
    {o = 'p', oi = 8, oa = nil, oo = nil},
    {o = -1, oi = 8, oa = nil, oo = nil}
}
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------

print("=== Testing getopt === ...")
test(t1optstring, t1argv, t1exp)
test(t2optstring, t2argv, t2exp)
test(t3optstring, t3argv, t3exp)
test(t4optstring, t4argv, t4exp)
test(t5optstring, t5argv, t5exp)
test(t6optstring, t6argv, t6exp)
test(t7optstring, t7argv, t7exp)
test(t8optstring, t8argv, t8exp)
test(t9optstring, t9argv, t9exp)


print("\n === Testing getopt_long === ...")
test(t10optstring, t10argv, t10exp, t10longs)
test(t11optstring, t11argv, t11exp, t11longs)
test(t12optstring, t12argv, t12exp, t12longs)
test(t13optstring, t13argv, t13exp, t13longs)
test(t14optstring, t14argv, t14exp, t14longs)
test(t15optstring, t15argv, t15exp, t15longs)

print(string.format("\n Fails: %s", fails))
if fails > 0 then os.exit(11) end
