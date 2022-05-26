#!/usr/bin/lua5.3

package.path = package.path .. ";../src/?.lua"

local moopt = require("moopt")
local utils = require("mutils")
local fails = 0
local num_passed = 0
local num_run = 0

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
    
    if #a ~= #b then
        if dbg then 
                print(utils.ptable(a, 2, "expected"))
                print(utils.ptable(b, 2, "actual"))
                print(string.format("\t --> difference found at index %s ", k))
        end
        return false 
    end

    for k,v in pairs(a) do 
        -- a and b are arrays or arrays
        if type(v) == "table" and type(b[k]) == "table" then
            if not (compare_arrays(v, b[k])) then 
                if dbg then 
                    print(utils.ptable(a, 2, "expected"))
                    print(utils.ptable(b, 2, "actual"))
                    print(string.format("\t --> difference found at index %s ", k))
                end
                return false 
            end

        else -- a and b are arrays of scalars (e.g. comparing opts_left tables)
            local res = compare_arrays(a,b) 
            if not res and dbg then
                print(utils.ptable(a, 2, "expected"))
                print(utils.ptable(b, 2, "actual"))
            end
            return res
        end
    end

    return true
end

function test(optstring, longs, argv, expected, expected_leftovers)
    num_run = num_run+1

    local actual_leftovers = {}
    local actual = moopt.test_getopt(argv, actual_leftovers, optstring, longs)
    local passed = compare(expected, actual)

    if passed then passed = compare(expected_leftovers, actual_leftovers) end

    local args = "["
    for _,v in ipairs(argv) do
        args = args .. string.format("\"%s\", ", v)
    end
    
    -- arg list is not empty
    if #args > 1 then
        args = args:sub(1,-3)
    end
    args = args .. "]"

    print(string.format(" | %s\t'%s' ~~ %s ", passed and "passed" or "FAILED!!!!!", optstring, args))
    if passed then num_passed = num_passed+1 end
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
}
local t1left = {}


local t2argv = {"-ab", "-carg", "-c"} 
local t2optstring = "+ab:c::"
local t2exp = {
    {o = 'a', oi =  1, oa = nil, oo = nil},
    {o = ':', oi =  2, oa = nil, oo = 'b'},
    {o = 'c', oi =  3, oa = 'arg', oo =  nil},
    {o = 'c', oi =  4, oa = nil, oo = nil},
}
local t2left = {}


local t3argv = {"-a", "what", "-barg", "-b", "-c", "arg", "-a", "--", "arg"}
local t3optstring = "+a:b::c:"
local t3exp = {
    {o = 'a', oi = 3, oa = 'what', oo = nil},
    {o = 'b', oi = 4, oa = "arg", oo = nil},
    {o = 'b', oi = 5, oa = nil, oo = nil},
    {o = 'c', oi = 7, oa = 'arg', oo = nil},
    {o = ':', oi = 8, oa = nil, oo = 'a'},
}
local t3left = {"arg"}


local t4argv = {"-abcdef", "--", "arg"}
local t4optstring = "?abcdef:"
local t4exp = {
    {o = 'a', oi = 1, oa = nil, oo = nil},
    {o = 'b', oi = 1, oa = nil, oo = nil},
    {o = 'c', oi = 1, oa = nil, oo = nil},
    {o = 'd', oi = 1, oa = nil, oo = nil},
    {o = 'e', oi = 1, oa = nil, oo = nil},
    {o = '?', oi = 2, oa = nil, oo = 'f'},
}
local t4left = {"arg"}


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
}
local t5left = {"arg"}


local t6argv = {"-157ag", "--", "-f"}
local t6optstring = ":135ag:f::"
local t6exp = {
    {o = '1', oi = 1, oa = nil, oo = nil},
    {o = '5', oi = 1, oa = nil, oo = nil},
    {o = '?', oi = 1, oa = nil, oo = '7'},
    {o = 'a', oi = 1, oa = nil, oo = nil},
    {o = ':', oi = 2, oa = nil, oo = 'g'},
}
local t6left = {"-f"}


local t7argv = {"-abc", "-er", "-g"}
local t7optstring = ":"
local t7exp = {
    {o = '?', oi = 1, oa = nil, oo = 'a'},
    {o = '?', oi = 1, oa = nil, oo = 'b'},
    {o = '?', oi = 2, oa = nil, oo = 'c'},
    {o = '?', oi = 2, oa = nil, oo = 'e'},
    {o = '?', oi = 3, oa = nil, oo = 'r'},
    {o = '?', oi = 4, oa = nil, oo = 'g'},
}
local t7left = {}


local t8argv = {"some"}
local t8optstring = ":"
local t8exp = {
}
local t8left = {'some'}


local t9argv = {}
local t9optstring = ":abc:"
local t9exp = {
}
local t9left = {}


local t17argv = {"-h", "one", "two", "three", "-d"}
local t17optstring = ":"
local t17exp = { {o='?', oi = 2, oa = nil, oo ='h'} }
local t17left = {"one", "two", "three", "-d"}

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
}
local t10left = {"-f"}


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
}
local t11left = {"myarg"}


-- no arguments
local t12argv = {}
local t12optstring = ":135ag:f::"
local t12longs = {
    test = {has_arg=0, val = 'x'},
    two = {has_arg=2, val = 'y'},
    flag = {has_arg=0, val = 'h'},
    path = {has_arg=1, val = 'p'},
    verbose = {has_arg=0, val = 'v'}
}
local t12exp = {}
local t12left = {}


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
}
local t13left = {"-f"}


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
}
local t14left = {"myarg"}


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
}
local t15left = {}


-- test where nothing gets parsed and all argv elements are left over
local t16argv = {"--verbose", "-v", "random", "--path", "-p", "-tlm", "--two", "--three", "arg1", "arg2", "arg3", "arg4"}
local t16optstring = "+"
local t16longs = {}
local t16exp = {
    {o = '?', oi = 2, oa = nil, oo = '--verbose'},
    {o = '?', oi = 3, oa = nil, oo = 'v'},
}
local t16left = {"random", "--path", "-p", "-tlm", "--two", "--three", "arg1", "arg2", "arg3", "arg4"}

---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------
---------------------------------------------------------------

print("=== Testing getopt === ...")

test(t1optstring, nil, t1argv, t1exp, t1left)
test(t2optstring, nil, t2argv, t2exp, t2left)
test(t3optstring, nil, t3argv, t3exp, t3left)
test(t4optstring, nil, t4argv, t4exp, t4left)
test(t5optstring, nil, t5argv, t5exp, t5left)
test(t6optstring, nil, t6argv, t6exp, t6left)
test(t7optstring, nil, t7argv, t7exp, t7left)
test(t8optstring, nil, t8argv, t8exp, t8left)
test(t9optstring, nil, t9argv, t9exp, t9left)
test(t17optstring, nil, t17argv, t17exp, t17left)

print("\n === Testing getopt_long === ...")
test(t10optstring, t10longs, t10argv, t10exp, t10left)
test(t11optstring, t11longs, t11argv, t11exp, t11left)
test(t12optstring, t12longs, t12argv, t12exp, t12left)
test(t13optstring, t13longs, t13argv, t13exp, t13left)
test(t14optstring, t14longs, t14argv, t14exp, t14left)
test(t15optstring, t15longs, t15argv, t15exp, t15left)
test(t16optstring, t16longs, t16argv, t16exp, t16left)

print(string.format("\n [ ] Passed: %s of %s", num_passed, num_run))
if num_passed < num_run  then os.exit(11) end
