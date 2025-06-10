-- Powerlevel10k theme for Zen Shell
-- Mirror of https://github.com/romkatv/powerlevel10k

-- ANSI color codes
local colors = {
    reset = "\27[0m",
    black = "\27[30m",
    red = "\27[31m",
    green = "\27[32m",
    yellow = "\27[33m",
    blue = "\27[34m",
    magenta = "\27[35m",
    cyan = "\27[36m",
    white = "\27[37m",
    bright_black = "\27[90m",
    bright_red = "\27[91m",
    bright_green = "\27[92m",
    bright_yellow = "\27[93m",
    bright_blue = "\27[94m",
    bright_magenta = "\27[95m",
    bright_cyan = "\27[96m",
    bright_white = "\27[97m",
    bg_black = "\27[40m",
    bg_red = "\27[41m",
    bg_green = "\27[42m",
    bg_yellow = "\27[43m",
    bg_blue = "\27[44m",
    bg_magenta = "\27[45m",
    bg_cyan = "\27[46m",
    bg_white = "\27[47m",
    bg_bright_black = "\27[100m",
    bg_bright_red = "\27[101m",
    bg_bright_green = "\27[102m",
    bg_bright_yellow = "\27[103m",
    bg_bright_blue = "\27[104m",
    bg_bright_magenta = "\27[105m",
    bg_bright_cyan = "\27[106m",
    bg_bright_white = "\27[107m"
}

-- Powerlevel10k icons
local icons = {
    -- Prompt
    prompt_char = {
        ok = "❯",
        error = "❯",
        ok_vicmd = "❮",
        error_vicmd = "❮"
    },
    
    -- Directory
    dir = {
        home = "~",
        home_subfolder = "~",
        default = "📁",
        open = "📂"
    },
    
    -- Git
    git = {
        branch = " ",
        commit = " ",
        tag = " ",
        stash = " ",
        merge = " ",
        pull = " ",
        push = " ",
        rebase = " ",
        cherry_pick = " ",
        bisect = " ",
        am = " ",
        revert = " ",
        clean = " ",
        dirty = " ",
        staged = "●",
        modified = "●",
        untracked = "?",
        conflicted = "!",
        ahead = "↑",
        behind = "↓",
        diverged = "↕",
        stashed = "⚑"
    },
    
    -- Status
    status = {
        ok = "✓",
        error = "✘",
        warning = "⚠",
        info = "ℹ"
    },
    
    -- Time
    time = {
        clock = " ",
        calendar = " "
    },
    
    -- System
    system = {
        cpu = " ",
        memory = " ",
        disk = " ",
        network = " "
    },
    
    -- Separators
    separators = {
        left_hard = " ",
        left_soft = " ",
        right_hard = " ",
        right_soft = " ",
        separator = " "
    }
}

-- Configuration
local config = {
    -- Prompt style
    prompt_style = "powerlevel10k",
    prompt_char_ok_color = colors.bright_green,
    prompt_char_error_color = colors.bright_red,
    
    -- Directory style
    dir_style = "full",
    dir_max_length = 40,
    dir_truncate_marker = "...",
    
    -- Git style
    git_style = "informative",
    git_icons = true,
    git_status_icons = true,
    
    -- Status line style
    status_style = "powerlevel10k",
    status_ok_color = colors.bright_green,
    status_error_color = colors.bright_red,
    status_warning_color = colors.bright_yellow,
    
    -- Time style
    time_style = "24h",
    time_format = "%H:%M:%S",
    date_format = "%d.%m.%y",
    
    -- System monitoring
    system_monitoring = true,
    system_warning_threshold = 80,
    
    -- Colors
    colors = {
        background = colors.bg_black,
        foreground = colors.white,
        accent = colors.bright_blue,
        success = colors.bright_green,
        warning = colors.bright_yellow,
        error = colors.bright_red
    }
}

-- Get current user
local function get_user()
    return os.getenv("USER") or "user"
end

-- Get hostname
local function get_host()
    local handle = io.popen("hostname")
    local result = handle:read("*a")
    handle:close()
    return result:gsub("%s+", "")
end

-- Get current working directory
local function get_cwd()
    local handle = io.popen("pwd")
    local result = handle:read("*l")
    handle:close()
    
    -- Replace home directory with ~
    local home = os.getenv("HOME")
    if home and result:sub(1, #home) == home then
        result = "~" .. result:sub(#home + 1)
    end
    
    -- Truncate if too long
    if #result > config.dir_max_length then
        local parts = {}
        for part in result:gmatch("[^/]+") do
            table.insert(parts, part)
        end
        
        if #parts > 2 then
            result = config.dir_truncate_marker .. "/" .. parts[#parts-1] .. "/" .. parts[#parts]
        end
    end
    
    return result
end

-- Get Git status
local function get_git_status()
    local status = {
        branch = "",
        commit = "",
        tag = "",
        stash = "",
        merge = "",
        pull = "",
        push = "",
        rebase = "",
        cherry_pick = "",
        bisect = "",
        am = "",
        revert = "",
        clean = true,
        dirty = false,
        staged = false,
        modified = false,
        untracked = false,
        conflicted = false,
        ahead = 0,
        behind = 0,
        diverged = false,
        stashed = false
    }
    
    -- Get branch name
    local handle = io.popen("git rev-parse --abbrev-ref HEAD 2>/dev/null")
    if handle then
        status.branch = handle:read("*a"):gsub("%s+$", "")
        handle:close()
    end
    
    if status.branch == "" then
        return nil
    end
    
    -- Get commit hash
    handle = io.popen("git rev-parse --short HEAD 2>/dev/null")
    if handle then
        status.commit = handle:read("*a"):gsub("%s+$", "")
        handle:close()
    end
    
    -- Get tag
    handle = io.popen("git describe --tags --exact-match 2>/dev/null")
    if handle then
        status.tag = handle:read("*a"):gsub("%s+$", "")
        handle:close()
    end
    
    -- Check for modified files
    handle = io.popen("git status --porcelain 2>/dev/null")
    if handle then
        for line in handle:lines() do
            if line:match("^%s*[AMDR]") then
                status.staged = true
                status.dirty = true
            elseif line:match("^%s*[MT]") then
                status.modified = true
                status.dirty = true
            elseif line:match("^%s*%?%?") then
                status.untracked = true
                status.dirty = true
            elseif line:match("^%s*[ADU]") then
                status.conflicted = true
                status.dirty = true
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
            status.diverged = behind > 0 and ahead > 0
        end
        handle:close()
    end
    
    return status
end

-- Get system status
local function get_system_status()
    local status = {
        cpu = 0,
        memory = 0,
        disk = 0,
        network = {
            up = 0,
            down = 0
        }
    }
    
    -- Get CPU usage
    local handle = io.popen("top -bn1 | grep 'Cpu(s)' | awk '{print $2}'")
    if handle then
        status.cpu = tonumber(handle:read("*a")) or 0
        handle:close()
    end
    
    -- Get memory usage
    handle = io.popen("free | grep Mem | awk '{print $3/$2 * 100.0}'")
    if handle then
        status.memory = tonumber(handle:read("*a")) or 0
        handle:close()
    end
    
    -- Get disk usage
    handle = io.popen("df -h / | tail -1 | awk '{print $5}' | sed 's/%//'")
    if handle then
        status.disk = tonumber(handle:read("*a")) or 0
        handle:close()
    end
    
    -- Get network usage
    handle = io.popen("cat /proc/net/dev | grep -v lo | awk '{print $2,$10}'")
    if handle then
        local up, down = handle:read("*n", "*n")
        if up and down then
            status.network.up = up
            status.network.down = down
        end
        handle:close()
    end
    
    return status
end

-- Format a segment
local function format_segment(text, fg_color, bg_color, icon)
    local segment = ""
    if icon then
        segment = segment .. icon .. " "
    end
    segment = segment .. text
    return string.format("%s%s%s%s", bg_color, fg_color, segment, colors.reset)
end

-- Build the prompt
local function build_prompt()
    local user = get_user()
    local host = get_host()
    local cwd = get_cwd()
    local git = get_git_status()
    local sys = get_system_status()
    local time = os.date(config.time_format)
    local date = os.date(config.date_format)
    
    local segments = {}
    
    -- User and host segment
    table.insert(segments, format_segment(
        string.format("%s@%s", user, host),
        colors.white,
        colors.bg_blue,
        icons.prompt_char.ok
    ))
    
    -- Directory segment
    table.insert(segments, format_segment(
        cwd,
        colors.white,
        colors.bg_magenta,
        icons.dir.default
    ))
    
    -- Git segment
    if git then
        local git_text = git.branch
        if git.tag ~= "" then
            git_text = git_text .. " " .. icons.git.tag .. git.tag
        end
        if git.ahead > 0 then
            git_text = git_text .. " " .. icons.git.ahead .. git.ahead
        end
        if git.behind > 0 then
            git_text = git_text .. " " .. icons.git.behind .. git.behind
        end
        if git.modified then
            git_text = git_text .. " " .. icons.git.modified
        end
        if git.staged then
            git_text = git_text .. " " .. icons.git.staged
        end
        if git.untracked then
            git_text = git_text .. " " .. icons.git.untracked
        end
        if git.conflicted then
            git_text = git_text .. " " .. icons.git.conflicted
        end
        if git.stashed then
            git_text = git_text .. " " .. icons.git.stashed
        end
        
        table.insert(segments, format_segment(
            git_text,
            colors.white,
            colors.bg_green,
            icons.git.branch
        ))
    end
    
    -- System status segment
    if config.system_monitoring and (sys.cpu > config.system_warning_threshold or 
                                   sys.memory > config.system_warning_threshold or 
                                   sys.disk > config.system_warning_threshold) then
        local sys_text = string.format(
            "%s%d%% %s%d%% %s%d%%",
            icons.system.cpu, sys.cpu,
            icons.system.memory, sys.memory,
            icons.system.disk, sys.disk
        )
        table.insert(segments, format_segment(
            sys_text,
            colors.white,
            colors.bg_red,
            icons.status.warning
        ))
    end
    
    -- Time segment
    table.insert(segments, format_segment(
        string.format("%s %s", date, time),
        colors.white,
        colors.bg_cyan,
        icons.time.clock
    ))
    
    -- Join segments with separators
    local prompt = table.concat(segments, icons.separators.separator)
    
    -- Add prompt symbol
    local prompt_symbol = user == "root" and icons.prompt_char.error or icons.prompt_char.ok
    local prompt_color = user == "root" and config.prompt_char_error_color or config.prompt_char_ok_color
    prompt = prompt .. "\n" .. prompt_color .. prompt_symbol .. " " .. colors.reset
    
    return prompt
end

-- Initialize plugin
local function init()
    print("Powerlevel10k theme loaded")
end

-- Get prompt
function get_prompt()
    return build_prompt()
end

-- Initialize the plugin
init() 