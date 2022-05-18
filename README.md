# moopt
Pure Lua implementation of POSIX `getopt` and GNU `getopt_long`


## Usage overview


### Using getopt()

```lua
    #!/usr/bin/lua5.3

    local moopt = require("moopt")
    for opt,optind,optarg,optopt in moopt.getopt(nil, arg, ":a:b:c::") do
        if opt == 'a' then
            print(string.format("option '%s' used, with optarg '%s'", opt, optarg))
        elseif opt == 'b' then
            print(string.format("option '%s' used, with optarg '%s'", opt, optarg))
        elseif opt == 'c' then
            print(string.format("option '%s' used, with optarg '%s'", opt, optarg))
        elseif opt == '?' then
            print("unknown option", optopt)
        elseif opt == ":" then
            print("missing argument to ", optopt)
        elseif opt==-1 then
            print("caught -1, end of parsing")
            break
        end
    end
```

Things to note:
 * **as with POSIX getopt, -1 is returned to signal the end of parsing.**
   However, advantage is taken of Lua's higher-level flexibility and
   and a for-loop iterator is used rather than a while loop. This
   makes usage a bit more straightforward. Ideally, iteration could be
   completely made use of by returning nil to automatically stop the
   itarator when the parsing is done -- instead of returning -1.
   However, this doesn't quite work because when nil is returned as
   the result (e.g. `opt`) the other return values (`optind`,
   `optarg`, `optopt`) are not returned anymore. This means the caller
   would not get the last `optind` value returned by `getopt`, needed
   if additional parsing must be carried out. This is not acceptable,
   so -1 is returned instead as described above.

 * **There are multiple options for the first character in
   `optstring`.** This is used to enable different functionality.
   Specifically:
    - '?' will make it so that the value returned in `opt` is '?' in
      case of error -- this is when either the argument is
      unrecognized (not specified in opstring) OR when the option is
      missing its required option argument.
    - ':' makes it so that the value returned in `opt` is '?' if an
      unrecognized option (not specified in optstring) is found.
      However, ':' is returned in case of an option missing its
      required option argument.
    - '+' enables extended behavior that is not POSIX-specified (note 
      this is the _reverse_ of GNU's getopt implementation in the C
      standard library, where '+' as the first `optstring` char
      enables _POSIXLY CORRECT_ behavior and disables extended,
      non-standard behavior). 
      For example, the caller can follow an option character with _two_
      colon characters in `optstring` to mean that it takes an
      _optional_ rather than a _mandatory_ option argument.
      For example:
       - `a:` specifies an option character 'a' that expects a _mandatory_
          option argument.
       - `a::` specifies an option character 'a' that expects an
         _optional_ option argument.

   The rest of the behavior when '+' is specifed is as if ':' were
   specified (rather than '?') as the first character in optstring.

   To disable this extended behavior, specify '?' or ':', rather than
   '+', as described above.

 * By default, error messages are printed out when an error condition is
   detected (e.g. missing optarg to option). This is usually not necessary
   because the module will print some diagnostic messages by default
   _unless_ `moopt.opterr` is set to 0. If the user wants to print their
   own diagnostics, then `moopt.opterr` _should_ be set to 0 to avoid
   duplicate error messages.


### Using `getopt_long`

POSIX's `getopt()` greatest disadvantage is that it only parses short
options and not longer, more mnemonic options. GNU extended the
behavior of `getopt()` such that it also parses long options,
specified with `--` instead of `-`.
This behavior is by definition _not_ POSIX-compliant.

To use `getopt_long()`, call `moopt.getopt_long()` just as you would
call `moopt.getopt()` but with an additional argument: a table that
defines a set of long options.

This table is of the following form:
```lua
    local longopts = {
        one = {val=VAL, has_arg=HAS_ARG},
        two = {val=VAL, has_arg=HAS_ARG}
        }
```
where:
 * `VAL` is a character (or anything else the user wants) that will
   be returned in `opt` when a match is found when parsing argv.
   Normally, the value returned here is a single character that _also_
   identifies a short option in `optstring`. In other words, the long
   option is the equivalent of a short option analogue. For example,
   '--verbose' and '-v' might be considered equivalent by an
   application.

 * `HAS_ARG` is:
    - 0 if the option does _not_ take an option argument
    - 1 if the option takes a _mandatory_ option argument
    - 2 if the option takes an _optional_ option argument. This is
      equivalent to specifying a double colon (`::`) after a
      character option in `optstring` when in extended mode.

```lua
    #!/usr/bin/lua5.3

    local moopt = require("moopt")

    local optstring = ':vdl::'
    local longopts = {
        verbose = {val = 'v', has_arg=0},
        debug = {val = 'd', has_arg = 0},
        log = {val = 'l', has_arg = 2}
    }

    -- default log path if none specified
    local default_log_path="/var/log/test.log"

    for opt,optind,optarg,optopt in moopt.getopt_long(nil, arg, optstring, longopts) do
        if opt == 'v' then
            print("called with verbose flag")
        elseif opt == 'd' then
            print(string.format("called with debug flag"))
        elseif opt == 'l' then
            print(string.format("called with log flag; will log to %s", optarg or default_log_path))
        elseif opt == '?' then
            print("unknown option", optopt)
        elseif opt == ":" then
            print("missing argument to ", optopt)
        elseif opt==-1 then
            print("caught -1, end of parsing")
            break
        end
    end
```

This sample program may be called in various ways. Assuming the name
of the Lua script is `test`:
 * ```./test -v --log='/tmp/mylog' --debug```
 * ```./test -dvl '/tmp/mylog'```
 * ```./test -vdl```
 * ```./test --verbose -d --log```
 * etc


## Tests

The tests are stored in `./tests`. Run `make tests` to execute them.

## License

This module is licensed under the 2-clause BSD license. See `LICENSE`
in the current working directory or run `make licence`.
