-- Enhanced Autosuggestions plugin for Zen Shell
-- Provides intelligent command suggestions based on history and usage patterns

local history = {}
local max_history = 1000
local suggestion_cache = {}
local last_input = ""
local last_suggestion = ""

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

-- Add command to history with frequency tracking
local function add_to_history(cmd)
    -- Remove if already exists (to move to front)
    for i, existing_cmd in ipairs(history) do
        if existing_cmd == cmd then
            table.remove(history, i)
            break
        end
    end
    
    table.insert(history, 1, cmd)
    if #history > max_history then
        table.remove(history)
    end
    save_history()
    
    -- Clear suggestion cache when new command is added
    suggestion_cache = {}
end

-- Fuzzy string matching (Levenshtein distance)
local function levenshtein_distance(s1, s2)
    local m, n = #s1, #s2
    local d = {}
    
    for i = 0, m do d[i] = {[0] = i} end
    for j = 0, n do d[0][j] = j end
    
    for j = 1, n do
        for i = 1, m do
            if s1:sub(i,i) == s2:sub(j,j) then
                d[i][j] = d[i-1][j-1]
            else
                d[i][j] = math.min(
                    d[i-1][j] + 1,    -- deletion
                    d[i][j-1] + 1,    -- insertion
                    d[i-1][j-1] + 1   -- substitution
                )
            end
        end
    end
    
    return d[m][n]
end

-- Find suggestions based on input with fuzzy matching
local function find_suggestions(input)
    if input == last_input and suggestion_cache[input] then
        return suggestion_cache[input]
    end
    
    local suggestions = {}
    local exact_matches = {}
    local fuzzy_matches = {}
    
    for _, cmd in ipairs(history) do
        if cmd:sub(1, #input) == input then
            table.insert(exact_matches, cmd)
        else
            local distance = levenshtein_distance(input, cmd:sub(1, #input))
            if distance <= 2 then  -- Allow for small typos
                table.insert(fuzzy_matches, {cmd = cmd, distance = distance})
            end
        end
    end
    
    -- Sort fuzzy matches by distance
    table.sort(fuzzy_matches, function(a, b) return a.distance < b.distance end)
    
    -- Combine exact and fuzzy matches
    for _, cmd in ipairs(exact_matches) do
        table.insert(suggestions, cmd)
    end
    for _, match in ipairs(fuzzy_matches) do
        table.insert(suggestions, match.cmd)
    end
    
    -- Cache the results
    last_input = input
    suggestion_cache[input] = suggestions
    
    return suggestions
end

-- Get the best suggestion for the current input
local function get_best_suggestion(input)
    if input == "" then return "" end
    
    local suggestions = find_suggestions(input)
    if #suggestions > 0 then
        return suggestions[1]:sub(#input + 1)
    end
    return ""
end

-- Initialize plugin
local function init()
    load_history()
    print("Enhanced Autosuggestions plugin loaded")
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

-- Get suggestion for current input
function get_suggestion(input)
    return get_best_suggestion(input)
end

-- Initialize the plugin
init() 