-- Autosuggestions plugin for Zen Shell
-- This plugin provides command suggestions based on command history

local history = {}
local max_history = 1000

-- Load command history from file
local function load_history()
    local history_file = os.getenv("HOME") .. "/.zencr/history"
    local file = io.open(history_file, "r")
    if file then
        for line in file:lines() do
            table.insert(history, line)
        end
        file:close()
    end
end

-- Save command history to file
local function save_history()
    local history_file = os.getenv("HOME") .. "/.zencr/history"
    local file = io.open(history_file, "w")
    if file then
        for _, cmd in ipairs(history) do
            file:write(cmd .. "\n")
        end
        file:close()
    end
end

-- Add command to history
local function add_to_history(cmd)
    table.insert(history, 1, cmd)
    if #history > max_history then
        table.remove(history)
    end
    save_history()
end

-- Find suggestions based on input
local function find_suggestions(input)
    local suggestions = {}
    for _, cmd in ipairs(history) do
        if cmd:sub(1, #input) == input then
            table.insert(suggestions, cmd)
        end
    end
    return suggestions
end

-- Initialize plugin
local function init()
    load_history()
    print("Autosuggestions plugin loaded")
end

-- Handle command execution
function execute_command(args)
    if #args == 0 then return false end
    
    local cmd = table.concat(args, " ")
    add_to_history(cmd)
    
    -- If the command is "suggest", show suggestions
    if args[1] == "suggest" then
        local input = args[2] or ""
        local suggestions = find_suggestions(input)
        
        if #suggestions > 0 then
            print("\nSuggestions:")
            for i, suggestion in ipairs(suggestions) do
                if i <= 5 then  -- Show only top 5 suggestions
                    print(string.format("%d. %s", i, suggestion))
                end
            end
        else
            print("No suggestions found")
        end
        return true
    end
    
    return false
end

-- Register plugin hooks
function on_command_entered(cmd)
    add_to_history(cmd)
    return false
end

-- Initialize the plugin
init() 