-- Git Prompt plugin for Zen Shell
-- Displays Git branch name and status in the prompt

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

-- Git status symbols
local symbols = {
    clean = "✓",
    modified = "●",
    staged = "●",
    untracked = "?",
    ahead = "↑",
    behind = "↓",
    diverged = "↕",
    stashed = "⚑"
}

-- Cache for Git status
local status_cache = {}
local cache_timeout = 2  -- seconds
local last_update = 0

-- Get current Git branch
local function get_git_branch()
    local handle = io.popen("git rev-parse --abbrev-ref HEAD 2>/dev/null")
    if not handle then return nil end
    
    local branch = handle:read("*a"):gsub("%s+$", "")
    handle:close()
    
    return branch ~= "" and branch or nil
end

-- Get Git status
local function get_git_status()
    local current_time = os.time()
    if current_time - last_update < cache_timeout then
        return status_cache
    end
    
    local status = {
        branch = get_git_branch(),
        modified = false,
        staged = false,
        untracked = false,
        ahead = 0,
        behind = 0,
        stashed = false
    }
    
    if not status.branch then
        return nil
    end
    
    -- Check for modified files
    local handle = io.popen("git status --porcelain 2>/dev/null")
    if handle then
        for line in handle:lines() do
            if line:match("^%s*[AMDR]") then
                status.staged = true
            elseif line:match("^%s*[MT]") then
                status.modified = true
            elseif line:match("^%s*%?%?") then
                status.untracked = true
            end
        end
        handle:close()
    end
    
    -- Check for stashed changes
    handle = io.popen("git stash list 2>/dev/null")
    if handle then
        status.stashed = handle:read("*a") ~= ""
        handle:close()
    end
    
    -- Check for ahead/behind
    handle = io.popen("git rev-list --count --left-right @{upstream}...HEAD 2>/dev/null")
    if handle then
        local behind, ahead = handle:read("*n", "*n")
        if behind and ahead then
            status.behind = behind
            status.ahead = ahead
        end
        handle:close()
    end
    
    status_cache = status
    last_update = current_time
    
    return status
end

-- Format Git status for prompt
local function format_git_prompt()
    local status = get_git_status()
    if not status then return "" end
    
    local parts = {}
    
    -- Branch name
    table.insert(parts, colors.cyan .. status.branch)
    
    -- Status indicators
    if status.modified then
        table.insert(parts, colors.red .. symbols.modified)
    end
    if status.staged then
        table.insert(parts, colors.green .. symbols.staged)
    end
    if status.untracked then
        table.insert(parts, colors.yellow .. symbols.untracked)
    end
    
    -- Remote status
    if status.ahead > 0 and status.behind > 0 then
        table.insert(parts, colors.magenta .. symbols.diverged)
    elseif status.ahead > 0 then
        table.insert(parts, colors.green .. symbols.ahead)
    elseif status.behind > 0 then
        table.insert(parts, colors.red .. symbols.behind)
    end
    
    -- Stash indicator
    if status.stashed then
        table.insert(parts, colors.yellow .. symbols.stashed)
    end
    
    return " " .. table.concat(parts, " ") .. colors.reset
end

-- Initialize plugin
local function init()
    print("Git Prompt plugin loaded")
end

-- Get prompt suffix
function get_prompt_suffix()
    return format_git_prompt()
end

-- Handle command execution
function execute_command(args)
    if #args == 0 then return false end
    
    -- If the command is "git-status", show detailed status
    if args[1] == "git-status" then
        local status = get_git_status()
        if not status then
            print("Not a Git repository")
            return true
        end
        
        print("Branch: " .. status.branch)
        print("Status:")
        print("  Modified: " .. (status.modified and "Yes" or "No"))
        print("  Staged: " .. (status.staged and "Yes" or "No"))
        print("  Untracked: " .. (status.untracked and "Yes" or "No"))
        print("  Ahead: " .. status.ahead)
        print("  Behind: " .. status.behind)
        print("  Stashed: " .. (status.stashed and "Yes" or "No"))
        return true
    end
    
    return false
end

-- Initialize the plugin
init() 