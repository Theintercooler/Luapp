local luvit = require "luvit.init"
local native = require "uv_native"
local process = require "luvit.process"
local traceback = require "debug".traceback
local table = require "table"

local origionalP = p
p = function() end

local function printUsage()
    process.stderr:write(("Usage: %s [-i | -r | -d] [-v] [-s] [--] <script file> [<Arguments>...]\n"):format(process.argv[0]))
    process.exit(1)
end

if not process.argv[1] then
    printUsage()
else
    local flags = {}
    local args = {}

    local parsingArgs = false
    for k, v in pairs(process.argv) do
        if v ~= process.argv[0] then
            parsingArgs = parsingArgs or (v:sub(1, 1) ~= '-')
            if parsingArgs then
                table.insert(args, v)
            else
                parsingArgs = v == '--'
                if not parsingArgs then
                    flags[v] = v
                end
            end
        end
    end
    
    if flags["-v"] then
        p = origionalP
    end

    local loadFunction = require
    if flags["-i"] then
        loadFunction = nil
    elseif flags["-d"] then
        loadFunction = dofile
    end
    if loadFunction ~= nil then
        process.luappArgv = process.argv

        local newArgs = {}
        for k, v in ipairs(args) do
            newArgs[k-1] = v
        end
        
        process.argv = newArgs

        assert(xpcall(function()
            loadFunction(newArgs[0])
        end, traceback))
    else
        local isSilent = flags["-s"] == "-s"
        p = origionalP -- Always verbose
        if not isSilent then
            process.stdout:write("lua>");
        end
        process.stdin:on("data", function(data)
            local suc, err = pcall(function() 
                local func = loadstring("p("..data..")")
                if not func then
                    func = assert(loadstring(data))
                end
                func()
            end)
            
            if not suc then
                process.stderr:write(err.."\n")
            end
            if not isSilent then
                process.stdout:write("lua>");
            end
        end)
        process.stdin:readStart()
    end
end

-- Start the event loop
native.run()

process.exit(process.exitCode or 0)
