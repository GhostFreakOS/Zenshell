# Zen Shell 🦈⚡  

**A blazing-fast, customizable, and plugin-driven shell built with C++!**  

## 🚀 Features  
- **Cross-platform**: Works on Arch Linux, Debian, Void, Fedora, OpenSUSE, and more.  
- **Plugin System**: Load only the plugins you need via `~/.zencr/config.lua`.  
- **Theming Support**: Customize colors and prompt styles easily.  
- **Zsh-like Power**: Autocompletion, syntax highlighting, and a powerful history system.  
- **Built for Performance**: Optimized with modern C++ for speed and efficiency.  
- **Lua plugins Support**: Add Lua Plugins Support 

## 📥 Installation  
### Wget one script installation
```
wget -qO- https://raw.githubusercontent.com/GhostFreakOS/Zenshell/main/install.sh | bash
```
### 1️⃣ Clone the Repository  
```sh
git clone https://github.com/D3f4ult-dev/Zenshell.git
cd Zenshell
```

### 2️⃣ Run the Installer  
```sh
chmod +x install.sh  
sudo ./install.sh  
```

### 3️⃣ Start Zen Shell  
```sh
zen  
```

## ⚙️ Configuration  

The config file is located at `~/.zencr/config.lua`. You can specify:  
- **Enabled plugins**:  
```lua
  -- List of active plugins
plugins = {
    "welcome.lua",
    "git_status.lua"
}
```  

- **Theming options**:  
 ```lua  
  -- Theme settings
theme = {
    prompt_color = "#4287f5",     -- Blue prompt (hex format)
    background = "#000000",       -- Black background (hex format)
    prompt_format = "[%u@%h %d]$ " -- Format: [username@hostname directory]$
}   
```
  
- **Custom Settings**:
```lua
-- Custom shell settings
settings = {
    history_size = 1000,
    auto_complete = true
}  
```

## 🔌 Plugin System  

Zen Shell supports dynamic plugins! Drop `.so` files into `~/.zencr/plugins/` and enable them in the config.
Zen Shell Also Support Lua programming luangauge in it   

## 🛠 Uninstallation  
```sh
sudo rm /bin/zen  
rm -rf ~/.zencr  
```

## Dependencies

- C++17 compatible compiler
- CMake 3.10 or higher
- Readline library
- Lua 5.1 or higher

## Building

```bash
mkdir build
cd build
cmake ..
make
```

## Installation

```bash
sudo make install
```

## Configuration

The shell looks for configuration in `~/.zencr/config.lua`. Here's an example configuration:

```lua
-- Active plugins
plugins = {
    "example.lua"
}

-- Theme settings
theme = {
    prompt_color = "#3498db",
    prompt_format = "[%u@%h %d]$ "
}
```

## Plugin Development

Plugins are written in Lua and should be placed in `~/.zencr/plugins/`. Each plugin should implement an `execute_command` function that returns true if it handled the command.

Example plugin:

```lua
function execute_command(args)
    if args[1] == "hello" then
        print("Hello, World!")
        return true
    end
    return false
end
```

## License

MIT License
