# ✨ Zen Shell - A Tranquil & Powerful Shell ✨

Zen Shell is a modern, fast, and customizable Unix shell designed to be a seamless blend of **Zsh** and **Oh My Zsh**, offering advanced features, plugin support, and a beautiful, colorful prompt.

## 💪 Features

- **Customizable Prompt**: A vibrant, easy-to-read command line interface.
- **Plugin System**: Extend functionality with `.zencr/plugins`.
- **Command Suggestions**: Type with ease and get auto-suggestions.
- **Syntax Highlighting**: Colorful commands to avoid mistakes.
- **History Navigation**: Scroll through past commands efficiently.
- **Alias Support**: Create shortcuts for your most-used commands.
- **Piping & Redirection**: Supports `|`, `>`, `<` like traditional shells.
- **Built-in Commands**: Includes `cd`, `exit`, and environment variable handling.

## 🛠️ Installation

### 1. Clone the Repository
```bash
git clone https://github.com/d3f4ult-dev/Zenshell
cd Zenshell
```

### 2. Compile & Install
```bash
chmod +x install.sh
sudo ./install.sh
```

### 3. Run Zen Shell
```bash
zen
```

## 🌟 Plugin System
Zen Shell loads plugins from `~/.zencr/plugins/`. To create a plugin:
```bash
mkdir -p ~/.zencr/plugins
cd ~/.zencr/plugins
echo "echo 'Hello from Plugin!'" > myplugin.sh
chmod +x myplugin.sh
```
It will automatically load on shell startup!

## 🌈 Theming
You can modify your Zen Shell prompt and colors in `~/.zencr/config`.

Example:
```bash
echo "export ZEN_PROMPT='\033[1;34m[%n@%d]$\033[0m '" > ~/.zencr/config
```

## 🛡️ Uninstallation
To remove Zen Shell:
```bash
sudo rm /usr/local/bin/zen
rm -rf ~/.zencr
```

## ✨ Join the Zen Community
For updates, support, and plugin sharing, join us at:
[GitHub](https://github.com/d3f4ult-dev/Zenshell) | [Website](bit.ly/shafiqz)

Stay Zen. Stay Efficient. 🌟

