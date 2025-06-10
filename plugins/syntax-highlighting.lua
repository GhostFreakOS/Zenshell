-- Syntax Highlighting plugin for Zen Shell
-- Provides real-time syntax highlighting for commands

-- ANSI color codes
local colors = {
    reset = "\27[0m",
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    magenta = "\27[35m",
    cyan = "\27[36m",
    white = "\27[37m",
    gray = "\27[90m"
}

-- Common command patterns
local patterns = {
    -- Commands
    command = {
        pattern = "^%s*([%w%-_]+)",
        color = colors.cyan
    },
    -- Options/flags
    option = {
        pattern = "%-%-?[%w%-_]+",
        color = colors.yellow
    },
    -- Strings
    string = {
        pattern = '"[^"]*"|\'[^\']*\'',
        color = colors.green
    },
    -- Numbers
    number = {
        pattern = "%d+",
        color = colors.magenta
    },
    -- Pipes and redirects
    operator = {
        pattern = "[|<>]",
        color = colors.blue
    },
    -- Variables
    variable = {
        pattern = "%$[%w_]+",
        color = colors.red
    },
    -- Comments
    comment = {
        pattern = "#.*$",
        color = colors.gray
    }
}

-- Common commands and their arguments
local command_args = {
    git = {
        "add", "commit", "push", "pull", "checkout", "branch", "merge", "status",
        "log", "diff", "remote", "fetch", "rebase", "reset", "stash"
    },
    docker = {
        "run", "build", "ps", "images", "exec", "stop", "start", "rm", "rmi",
        "network", "volume", "compose"
    },
    apt = {
        "install", "remove", "update", "upgrade", "search", "show", "list",
        "purge", "autoremove"
    }
}

-- Highlight a single token
local function highlight_token(token, type)
    if patterns[type] then
        return patterns[type].color .. token .. colors.reset
    end
    return token
end

-- Split command into tokens
local function tokenize_command(cmd)
    local tokens = {}
    local pos = 1
    
    while pos <= #cmd do
        local matched = false
        
        -- Try each pattern
        for type, pattern in pairs(patterns) do
            local match = cmd:match(pattern.pattern, pos)
            if match then
                table.insert(tokens, {
                    text = match,
                    type = type
                })
                pos = pos + #match
                matched = true
                break
            end
        end
        
        -- If no pattern matched, add the character as plain text
        if not matched then
            table.insert(tokens, {
                text = cmd:sub(pos, pos),
                type = "plain"
            })
            pos = pos + 1
        end
    end
    
    return tokens
end

-- Highlight a command
local function highlight_command(cmd)
    local tokens = tokenize_command(cmd)
    local highlighted = ""
    
    for _, token in ipairs(tokens) do
        highlighted = highlighted .. highlight_token(token.text, token.type)
    end
    
    return highlighted
end

-- Check if a command is valid
local function validate_command(cmd)
    local first_word = cmd:match("^%s*([%w%-_]+)")
    if not first_word then return true end
    
    -- Check if it's a known command with arguments
    for cmd_name, args in pairs(command_args) do
        if first_word == cmd_name then
            local second_word = cmd:match("^%s*[%w%-_]+%s+([%w%-_]+)")
            if second_word then
                for _, valid_arg in ipairs(args) do
                    if second_word == valid_arg then
                        return true
                    end
                end
                return false  -- Invalid argument for known command
            end
        end
    end
    
    return true  -- Unknown command, assume valid
end

-- Initialize plugin
local function init()
    print("Syntax Highlighting plugin loaded")
end

-- Handle command execution
function execute_command(args)
    if #args == 0 then return false end
    
    local cmd = table.concat(args, " ")
    
    -- If the command is "highlight", show highlighted version
    if args[1] == "highlight" then
        local input = args[2] or ""
        print(highlight_command(input))
        return true
    end
    
    return false
end

-- Register plugin hooks
function on_command_entered(cmd)
    -- Validate command before execution
    if not validate_command(cmd) then
        print(colors.red .. "Invalid command or argument" .. colors.reset)
        return true  -- Prevent execution
    end
    return false
end

-- Get highlighted version of command
function get_highlighted_command(cmd)
    return highlight_command(cmd)
end

-- Initialize the plugin
init() 