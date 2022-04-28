#!/usr/bin/lua5.3

--[[
    (c) 2022 vcsaturninus@protonmail.com

    Implementation of getopt function as per POSIX guidelines. 
    This imeplementation seeks to comply[1] with:
      https://pubs.opengroup.org/onlinepubs/9699919799/functions/getopt.html

    Also of relevance: 
      https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html

    [1] Compliance is not absolute. Specifically, Lua offers much more flexible
        features than C: multiple return values, iterators etc. These are
        made use of here such that:

         - getopt doesn't return the next option directly, and instead it
           returns an iterable object that can be called by the 'for' iterator. 
           -1 is still returned rather than nil, so the caller must test the
           first return value and break out of the loop if it's -1. The reason nil
           is not returned is so that the body of the loop is executed one more
           time in order for the caller to be able to retrieve the value
           of optind that's returned last.

        -  Lua doesn't support pointers (the only types passed by reference are
           tables) so multiple values are returned instead to the caller, rather
           than updating optind, opopt etc via pointers or global/extern variables.
    

    NOTE: getopt_long is a GNU extension, not POSIX/SUS-compliant. This implementation
    of getopt_long is similar but not identical to GNU's C getopt_long, in line with
    Lua's strengths and weaknesses.
--]]

local M={}

-- returned when running into an unknown option (char not contained in optstring), 
-- or, provided the first char of optstring is NOT ':', when running into an option 
-- that expects an argument and the argument is missing.
-- NOTE that in EXTENDED mode, ':' is returned in the second case regardless of the
-- first char in optstring
local UNKNOWN = '?'

-- returned when running into an option that expects a (non-optional) argument
-- that isn't found -- provided the first char of optstring is ':' and not '?'.
-- NOTE that in EXTENDED mode, regardless of what the first char in optstring is,
-- ':' will be returned in such a case.
local COLON = ':'

-- marks the end of parsing. The caller should stop its loop when this is returned.
local ITER_END = -1

-- Used to allow the caller to inhibit any stder diagnostics printed by getopt.
-- Unless set to 0, and provided the first char in optstring is NOT ':', 
-- print diagnostic msg to stderr when error found.
M.opterr = 1          

--------------------------------------------------------------------------------
--[[
    Terminate msg with newline if not already newline-terminated
    and print it out to stderr. Print IFF .opterr != 0.
--]]
function complain(...)
    local msg = string.format(...)
    msg = msg:sub(#msg,#msg) ~= "\n" and msg .. "\n" or msg

    if M.opterr ~= 0 then
        io.stderr:write(msg)
    end
end

--[[
    Populate the 'options' table with a per-option structure holding 
    the name of and other information germaine to the option, such as:
     - whether it expects an option argument ('expects')
     - whether the option argument (provided we're operating in EXTENDED
       mode) itself is optional (when two ':' follow the option char in optstring):
       ('ooa').
--]]
function save_shorts(opts, optstring, extended_mode) 
    optstring = optstring:sub(2)    -- skip first char in optstring

    -- sanitize optstring: must only contain alphanumerics and ':'
    local idx = optstring:find("[^%w:]")
    if idx then
        complain("invalid char '%s' found in optstring '%s' at index %i", optstring:sub(idx, idx), optstring, idx)
    end

    -- if opt is followed by a single ':' in optstring, it means it expects
    -- an option argument. If it is followed by two ':' , that means the option
    -- argument expected is itself optional and no error condition is caused if
    -- the option argument is left unspecified. Note this is a GNU extension and 
    -- not posixly correct so it will only work if this module is run in EXTENDED
    -- mode.
    for opt,oa,ooa in optstring:gmatch("(%w)(:?)(:?)") do
        opts[opt] = {expects = (oa ~= '' and true or false)}

        if extended_mode and oa then -- option arg can only be optional in EXTENDED mode
            -- only add this field for options that expect an optarg 
            if opts[opt]["expects"] then
                opts[opt]["ooa"] = (ooa ~= '' and true or false)
            end
        end
    end
end

--[[
    Copy options from the longs table to opts so that we have
    a single table for querying in the same way regardless of 
    option type (short or long). Storing all of them in a table
    allows for O(1) queries.

--> opts 
    Table to store all options, long and short. It must also be populated 
    with short options via 'save_shorts()'.

--> longs
    The arary of option structs (tables) to be passed to getopt_long().
--]]
function save_longs(opts, longs)
    for k,v in pairs(longs) do
        opts[k] = {
            expects = (v.has_arg > 0) and true or false,
            val = v.val
        }
        if opts[k]["expects"] then
            opts[k]["ooa"] = v.has_arg == 2
        end
    end
end

--[[
    Return the char at the specified index in ARG.
    ARG is an argv element.
--]]
function next_opt(arg, idx)
    return arg:sub(idx,idx)
end

--[[
    Get the option argument. This function must only be called when the option
    is determined to be in fact expecting an option argument.

    If partial is true, it means the option argument follows the current option
    in the same argv element e.g. -barg, so the function will return the rest
    of the current argv element starting at idx. idx must be 1 more than the index
    of the current option character. For example, the index of 'b' in '-barg' is 2 
    (as 1 is '-') and so we want the substring starting at idx 3.

    If partial is false, idx is disregarded and arg is returned.
    This is when the option character was the last character in the previous argv
    element and so the option argument was not a substring in that same element and is
    instead a whole argv element of its own.
    In this case, since idx is disregarded, this is equivalent to calling get_optarg()
    with arg as the only argument as the other two will automatically be filled in as nil.
--]]
function get_optarg(arg, idx, partial)
    if partial then 
        return arg:sub(idx)  -- return rest of string starting at idx
    end
    return arg  -- return whole argv element
end

--[[
    Return the optarg passed to a long option. This is either part of the 
    same token as the long option, separated from it by an equals sign,
    or is a standalone token separated from the long option by whitespace.

    If arg contains an = sign, then return the substring after it (the optarg),
    else assume arg is a standalone optarg token and return it whole.
--]]
function get_longarg(arg)
    local i = arg:find('=')
    if not arg:find('=')  then return arg end
    return arg:sub(i+1)
end

--[[
    True if elem (argv element) is a valid short option, else False.
--]]
local function is_option(elem)
    return string.match(tostring(elem), "^%-[%w-]+") and true or false
end

--[[
    True if elem (argv element) is a valid long option, else False.
--]]
local function is_long_option(elem)
    return string.match(tostring(elem), "^%-%-%w+") and true or false
end

--[[
    Return true if the option at arg[idx] is the last char in the argv element arg,
    else false.
--]]
local function comes_last(arg, idx)
    return #arg == idx
end

--[[
    Parse the elements in argv according to the optstring specification and
    the (optional) longopts array of long option structures. 
    getopt() is simply a wrapper around getopt_long() here, as the latter 
    supports both short and long options. For getopt() (short-options only)
    functionality, this function can simply be called with longopts unspecified
    (nil, NOT empty array).

--> argc
    The length of argv : #arg

--> argv
    Lua's arg

--> optstring
    A getopt optstring as per POSIX specification. 
    The first char in optstring can be used to specify the mode of
    operation of the getopt function. POSIX mandates this must be either
    ? or : and that implementations can allow others as an extension. 

    This implementation acccepts '+' as the first optstring character
    to instruct the function to only use POSIXLY CORRECT features. 
    By default, this function uses slightly extended behavior.
    This is much like glibc's getopt implementation.

<-- opt, optind, optarg, optopt
    POSIX specifies the getopt function should return only an int, which is
    the current option character, '?', ':' or -1 to signal the end of parsing.
    Variables must normally be declared extern: the getopt source file has 
    declared optind, optopt, optarg as globals and updates them there.

    This is clusmy in Lua and much better is to just have the function return
    all of these as return values. The caller can then easily test these.

    NOTE:
     * opt is the option character or ':' or '?' or -1
     * optind is an index into argv for the next parsing action
     * optarg is any optarg found for opt, else nil
     * optopt is the current character opt found to have caused an error
       condition, else nil.
--]]
function M.getopt_long(argc, argv, optstring, longopts)
    local options = {}  -- save long and short options here for O(1) access
    local optind = 1    -- index of argv element containing the next option
    local argv = argv   -- command-line elements to be parsed
    local cidx = 1      -- index in argv element of next SHORT option char
    local POSIXLY_CORRECT = false -- do not use extended features (e.g. optional optargs)
    local EXTENDED_MODE = false   -- do use extended features at the expence of greater compliance

    if optstring:sub(1,1) == "+" then
        POSIXLY_CORRECT = true
    else
        EXTENDED_MODE = true
    end
    save_shorts(options, optstring, EXTENDED_MODE)
    if longopts then save_longs(options, longopts) end

    -- return this as object iterable with the 'for' iterator
    local function __getopt_long()
        local opt, optarg, optopt
        local arg = argv[optind]
        
        -- we've run out of argv elements'
        if not arg then
            return ITER_END, optind, optarg, optopt 

        -- end of option parsing: -1 must be returned AND optind incremented
        elseif arg == "--" then
            optind = optind+1
            return ITER_END, optind, optarg, optopt 

        -- long option: deal with it; only look at an argv element starting with '--'
        -- as a long option if longopts is true (=> function called in getopt_long mode)
        elseif longopts and is_long_option(arg) then
            optind, cidx = optind+1, 1
            local opt, optarg = arg:match("([%w_-]*)=?([%w_-]*)")
            if optarg ==  '' then optarg = nil end
            if opt == '' then opt = nil end

            if not opt then 
                complain("cannot parse argv element '%s'", arg) 
                return ITER_END, optind, optarg, optopt
            end
            opt = opt:sub(3)

            if not options[opt] then
                complain("unknown option '--%s'", opt)
                return UNKNOWN, optind, optarg, "--" .. opt
            end

            if options[opt]["expects"] then
                -- assume it was not in the same token separated by =
                -- but in a separate token
                if not optarg then optarg=argv[optind] end
     
                -- ensure this token is really an argument, not an option
                if optarg and not is_option(optarg) and not is_long_option(optarg) and optarg ~= "--" then
                    optind=optind+1
                else
                    optarg = nil
                end

                -- if missing optarg and option arguments are NOT optional
                if not options[opt]["ooa"] and not optarg then
                    complain("missing argument to '--%s'", opt)
                    return optstring:sub(1,1) == ":" and COLON or UNKNOWN, optind, optarg, opt
                end
            end

            -- does not expect and optarg or optarg has been obtained
            return options[opt]["val"] or opt, optind, optarg, optopt
        
        -- not a long option: check if valid short option instead
        -- the element in argv must be a string of one
        -- or more option chars and possibly an optarg
        elseif is_option(arg) then
            -- get next short option char from within current argv element
            cidx = cidx+1
            local opt = next_opt(arg, cidx)

            -- if the opt char is unrecognized, return '?'
            if not options[opt] then 
                optopt = opt
                if comes_last(arg, cidx) then
                    optind, cidx = optind+1, 1
                end
                return UNKNOWN, optind, optarg, optopt

            else  -- option recognized
                if not options[opt]["expects"] then -- option does not expect an option argument
                    -- if we've looked at all chars in current argv element, move on to the next
                    if comes_last(arg, cidx) then
                        optind, cidx = optind+1, 1
                    end
                
                else -- option expects an option argument
                    if comes_last(arg, cidx) then  -- if option is the last char in argv element
                        optarg = get_optarg(argv[optind+1])  -- get optarg in next argv element

                        -- if this is not a valid optarg for one of these reasons
                        if not optarg or optarg == "--" or is_option(optarg) or is_long_option(optarg) then 
                            optarg = nil
                            optind, cidx = optind+1, 1
                            -- if invalid optarg and optional optargs are not enabled, register as error
                            if not options[opt]["ooa"] then
                                complain("missing argument to '-%s'", opt)
                                optopt = opt
                                return optstring:sub(1,1) == ":" and COLON or UNKNOWN, optind, optarg, optopt
                            end
                            
                        else   -- valid optarg
                            optind, cidx = optind+2, 1
                        end
 
                    else  -- doesn't come last; read rest of string
                        optarg = get_optarg(arg, cidx+1, true)
                        optind, cidx = optind+1, 1
                    end -- option char does not come last
                end -- option expects option argument
            end -- option recognized

            return opt, optind, optarg, optopt

        -- not a valid short or long option: -1 must be returned in these circumstances, 
        -- with optind left unchanged; a valid long option is also a valid short
        -- option because it starts with '-' and the second '-' is a valid option
        -- character; otoh a valid short option is not a valid long option because
        -- it only starts with a single '-'
        else
            return ITER_END, optind, optarg, optopt
        end
    end

    return __getopt_long
end

-- wrapper around getopt_long()
function M.getopt(argc, argv, optstring)
    return M.getopt_long(argc, argv, optstring, nil)
end

--[[
    Returns an array of tables that can be used for testing
    and validating the parsing.

    Each table corresponds to one parsed option and is of the following 
    form:
    {o = OPT, oi = OPTIND, oa = OPTARG, oo = OPTOPT}
--]]
function M.test_getopt(argc, argv, optstring, longopts)
    local t = {}
    M.opterr = 0

        for opt, optind, optarg, optopt in M.getopt_long(argc, argv, optstring, longopts) do
        table.insert(t, {o = opt, oi = optind, oa = optarg, oo = optopt})

        if opt == -1 then 
            break 
        end
    end

    return t
end

return M
