
local M = {}
M._VERSION = 1
M._DESCRIPTION = "Common function used across repos, mainly for testing/debugging."

local function addtrailing(str, char)
    if str and str[#str] ~= char then
        return str .. char
    end
end

function M.ptable(table_obj, offset, prel)
    -- everything gets concatenated with this, which is the final result ultimately returned
    local res=""

    --prelude before the table proper
    if prel then
        prel = addtrailing(prel, "\n")
        res = res .. prel
    end
    res = res .. "{\n"

    -- closure
    function tts(table_obj, off)

        -- each item in the array is either a table, in which case recurse
        -- or a scakar that can be deal with on the spot without recursion
        for k,v in pairs(table_obj) do
            local curr_lvl_str = ""
           -- enclose key and value in quotation marks if they're strings to make
            -- the output more intuitive
            val = tostring(v)
            key = tostring(k)

            if type(v) == "string" then
               val = string.format("\"%s\"", val)
            end

            if type(k) == "string" then
               key = string.format("\"%s\"", key)
            end

            -- item is table: print or recurse; traverse table
            -- __index must be skipped as it often points to the same table or a metatable
            -- so it's very likely to cause an infinite loop!--> do NOT recurse on __index if a table
            if type(v) == "table" and k ~= "__index" then -- recurse
                res = res .. string.rep(" ", off)
                res = res .. "[" .. tostring(key) .. "]" .. " : { " .. "\n"  -- [<key>]
                tts(v, off+offset) -- recurse and indent appropriately
                res = res ..  string.rep(" ", off)
                res = res .. "},\n"

            else -- item is scalar
                res = res .. string.rep(" ", off)
                -- surround the value with quotation marks if it's a string,
                -- so as to make it more explicit
                res = res .. "[" .. tostring(key) .. "]" .. " : " .. tostring(val) .. ",\n"  -- [<key] : <value>
            end
        end

        if not (res:sub(-2,-1) == ",\n") then return end -- assume empty table
        -- else any recursive call ends here; we need to remove the trailing comma
        -- for the last item in any table
        res = string.sub(res, 1, #res-2)
        res = addtrailing(res, "\n")
    end

    -- table to string;
    tts(table_obj, offset)

    -- end
    res = res .. "}\n"

    return res
end


return M
