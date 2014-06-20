local luvit = require "luvit.init"
local native = require "uv_native"
local process = require "luvit.process"
local traceback = require "debug".traceback

local origionalP = p
p = function() end

local function printUsage()
    process.stderr:write(("Usage: %s [-i | -r | -d] [-v] <script file> [<Arguments>...]\n"):format(process.argv[0]))
    process.exit(1)
end

if not process.argv[1] then
    printUsage()
else
    local loadFunction = require
    local skipArgs = 1

    if process.argv[1]:sub(1, 1) == '-' then
        skipArgs = 2
        if process.argv[1] == '-i' then
            loadFunction = nil
        elseif process.argv[1] == '-d' then
            loadFunction = _G.dofile
        elseif process.argv[1] == '-r' then
        else
            return printUsage()
        end
    end

    if process.argv[2] and process.argv[2]:sub(1, 1) == '-' then
        if process.argv[2] == '-v' then
            skipArgs = 3
            p = origionalP
        end
    end

    if loadFunction ~= nil then
        process.luappArgv = process.argv

        local newArgs = {}
        for k, v in pairs(process.argv) do
            if k > skipArgs then
                newArgs[k-skipArgs] = v
            elseif newArgs[0] then
                newArgs[0] = newArgs[0] .. " " .. v
            else
                newArgs[0] = v
            end
        end
        
        process.argv = newArgs

        assert(xpcall(function()
            loadFunction(process.luappArgv[skipArgs])
        end, traceback))
    else
        p = origionalP -- Always verbose
        process.stdout:write("lua>");
        process.stdin:on("data", function(data)
            local suc, err = pcall(function() 
                local func = loadstring("p("..data..")")
                if not func then
                    func = assert(loadstring(data))
                end
                p(func())
            end)
            
            if not suc then
                process.stderr:write(err.."\n")
            end
            process.stdout:write("lua>");
        end)
        process.stdin:readStart()
    end
end

-- Start the event loop
native.run()

process.exit(process.exitCode or 0)