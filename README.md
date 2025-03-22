# Zen Shell 🦈⚡  

**A blazing-fast, customizable, and plugin-driven shell built with C++!**  

## 🚀 Features  
- **Cross-platform**: Works on Arch Linux, Debian, Void, Fedora, OpenSUSE, and more.  
- **Plugin System**: Load only the plugins you need via `~/.zencr/config`.  
- **Theming Support**: Customize colors and prompt styles easily.  
- **Zsh-like Power**: Autocompletion, syntax highlighting, and a powerful history system.  
- **Built for Performance**: Optimized with modern C++ for speed and efficiency.  
- **Lua plugins Support**: Add Lua Plugins Support 

## 📥 Installation  

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

The config file is located at `~/.zencr/config`. You can specify:  
- **Enabled plugins**:  
  ```ini  
  plugin:suggestions  
  plugin:history  
  plugin:syntax_highlight  
  ```  
- **Theming options**:  
  ```ini  
  theme:prompt_color=34  # Blue prompt  and choose colors with hex format 
  theme:background=black  
  ```  

## 🔌 Plugin System  

Zen Shell supports dynamic plugins! Drop `.so` files into `~/.zencr/plugins/` and enable them in the config.
Zen Shell Also Support Lua programming luangauge in it   

## 🛠 Uninstallation  
```sh
sudo rm /bin/zen  
rm -rf ~/.zencr  
```
