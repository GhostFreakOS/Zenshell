#include <iostream>
#include <vector>
#include <string>
#include <sstream>
#include <sys/stat.h>
#include <unistd.h>
#include <limits.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <dirent.h>
#include <cstring>
#include <readline/readline.h>
#include <readline/history.h>
#include <dlfcn.h>
#include <unordered_map>
#include <algorithm>
#include <lua.hpp>
#include <cstdlib>
#include <regex>

#define MAX_INPUT 255

using namespace std;

// Global variables
vector<string> active_plugins;
unordered_map<string, string> theme_settings;
string home_dir;
lua_State *L = nullptr;

/**
 * @brief Converts hex color code to ANSI escape sequence
 */
string hex_to_ansi(const string& hex) {
    string clean_hex = hex;
    if (hex[0] == '#') {
        clean_hex = hex.substr(1);
    }

    // Convert hex to RGB
    if (clean_hex.length() == 6) {
        int r, g, b;
        sscanf(clean_hex.c_str(), "%02x%02x%02x", &r, &g, &b);
        return "\033[38;2;" + to_string(r) + ";" + to_string(g) + ";" + to_string(b) + "m";
    }

    // Return default if invalid
    return "\033[0m";
}

/**
 * @brief Gets the user's home directory
 */
string get_home_dir() {
    const char* home = getenv("HOME");
    return home ? string(home) : "";
}

/**
 * @brief Returns the hostname of the system
 */
string get_hostname() {
    char hostbuffer[HOST_NAME_MAX];
    if (gethostname(hostbuffer, sizeof(hostbuffer)) == 0) {
        return std::string(hostbuffer);
    } else {
        return "unknown";
    }
}

/**
 * @brief Initializes the Lua environment
 */
bool init_lua() {
    L = luaL_newstate();
    if (!L) return false;

    luaL_openlibs(L);
    return true;
}

/**
 * @brief Loads the configuration file using Lua
 */
void load_config() {
    if (!L) {
        cerr << "Lua environment not initialized" << endl;
        return;
    }

    string config_path = home_dir + "/.zencr/config.lua";

    if (luaL_dofile(L, config_path.c_str())) {
        cerr << "Error loading config: " << lua_tostring(L, -1) << endl;
        lua_pop(L, 1);
        return;
    }

    // Get plugins table
    lua_getglobal(L, "plugins");
    if (lua_istable(L, -1)) {
        lua_pushnil(L);
        while (lua_next(L, -2) != 0) {
            if (lua_isstring(L, -1)) {
                active_plugins.push_back(lua_tostring(L, -1));
            }
            lua_pop(L, 1);
        }
    }
    lua_pop(L, 1);

    // Get theme settings
    lua_getglobal(L, "theme");
    if (lua_istable(L, -1)) {
        lua_pushnil(L);
        while (lua_next(L, -2) != 0) {
            if (lua_isstring(L, -2) && lua_isstring(L, -1)) {
                theme_settings[lua_tostring(L, -2)] = lua_tostring(L, -1);
            }
            lua_pop(L, 1);
        }
    }
    lua_pop(L, 1);
}

/**
 * @brief Loads Lua plugins
 */
void load_plugins() {
    if (!L) {
        cerr << "Lua environment not initialized" << endl;
        return;
    }

    string plugins_dir = home_dir + "/.zencr/plugins";

    DIR *dir = opendir(plugins_dir.c_str());
    if (!dir) {
        cerr << "Could not open plugins directory: " << plugins_dir << endl;
        return;
    }

    struct dirent *entry;
    while ((entry = readdir(dir))) {
        string name = entry->d_name;
        if (name.length() > 4 && name.substr(name.length() - 4) == ".lua") {
            // Check if this plugin is active
            if (find(active_plugins.begin(), active_plugins.end(), name) != active_plugins.end()) {
                string path = plugins_dir + "/" + name;
                if (luaL_dofile(L, path.c_str())) {
                    cerr << "Error loading plugin " << name << ": " << lua_tostring(L, -1) << endl;
                    lua_pop(L, 1);
                } else {
                    cout << "Loaded plugin: " << name << endl;
                }
            }
        }
    }
    closedir(dir);
}

/**
 * @brief Generates the prompt string based on theme settings
 */
string generate_prompt() {
    string username = getenv("USER") ? getenv("USER") : "unknown";
    string hostname = get_hostname();

    char dir[MAX_INPUT];
    getcwd(dir, MAX_INPUT);

    // Convert home directory to tilde
    string pwd(dir);
    if (pwd.find(home_dir) == 0) {
        pwd = "~" + pwd.substr(home_dir.length());
    }

    // Apply theme
    string prompt_color = theme_settings.count("prompt_color") ?
                          hex_to_ansi(theme_settings["prompt_color"]) :
                          "\033[34m"; // Default blue

    string reset_color = "\033[0m";

    // Format the prompt (customize as you wish)
    string prompt_format = theme_settings.count("prompt_format") ?
                          theme_settings["prompt_format"] :
                          "[%u@%h %d]$ ";

    // Replace placeholders in prompt format
    string prompt = prompt_format;
    prompt = regex_replace(prompt, regex("%u"), username);
    prompt = regex_replace(prompt, regex("%h"), hostname);
    prompt = regex_replace(prompt, regex("%d"), pwd);

    return prompt_color + prompt + reset_color;
}

/**
 * @brief Tokenizes the input string
 */
vector<string> tokenize(const string &input) {
    vector<string> args;
    istringstream stream(input);
    string token;
    while (stream >> token) {
        args.push_back(token);
    }
    return args;
}

/**
 * @brief Executes a shell command
 */
void execute_command(vector<string> args) {
    if (args.empty()) return;

    // Handle built-in commands
    if (args[0] == "cd") {
        if (args.size() < 2) {
            // Change to home directory if no argument
            if (chdir(home_dir.c_str()) != 0) {
                perror("cd");
            }
        } else if (chdir(args[1].c_str()) != 0) {
            perror("cd");
        }
        return;
    }

    if (args[0] == "exit" || args[0] == "quit") {
        cout << "Goodbye!" << endl;
        exit(0);
    }

    // Execute Lua functions if registered by plugins
    if (L) {
        lua_getglobal(L, "execute_command");
        if (lua_isfunction(L, -1)) {
            lua_newtable(L);
            for (size_t i = 0; i < args.size(); i++) {
                lua_pushstring(L, args[i].c_str());
                lua_rawseti(L, -2, i+1);
            }

            if (lua_pcall(L, 1, 1, 0) != 0) {
                cerr << "Error executing Lua command handler: " << lua_tostring(L, -1) << endl;
                lua_pop(L, 1);
            } else if (lua_isboolean(L, -1) && lua_toboolean(L, -1)) {
                // Command was handled by Lua
                lua_pop(L, 1);
                return;
            }
            lua_pop(L, 1);
        } else {
            lua_pop(L, 1);
        }
    }

    // Fork and execute system command
    pid_t pid = fork();
    if (pid == 0) {
        // Child process
        vector<char*> c_args;
        for (auto &arg : args) c_args.push_back(&arg[0]);
        c_args.push_back(nullptr);

        execvp(c_args[0], c_args.data());
        perror("exec");
        exit(1);
    } else if (pid > 0) {
        // Parent process
        int status;
        waitpid(pid, &status, 0);
    } else {
        perror("fork");
    }
}

/**
 * @brief helper 
 */
void handle_sigint(int sig) {
    cout << "\nUse the 'exit' command to quit the shell." << endl;
}

/**
 * @brief Main function
 */
int main() {
    cout << "Welcome to Zen Shell!" << endl;
    
    // Set up signal handler for SIGINT
    signal(SIGINT, handle_sigint);

    // Get home directory
    home_dir = get_home_dir();
    if (home_dir.empty()) {
        cerr << "Could not determine home directory" << endl;
        return 1;
    }

    // Initialize Lua
    if (!init_lua()) {
        cerr << "Failed to initialize Lua environment" << endl;
        return 1;
    }

    // Create config directory if it doesn't exist
    string config_dir = home_dir + "/.zencr";
    string plugins_dir = config_dir + "/plugins";

    // This is a simple check, in production you'd want to create these directories if missing
    if (access(config_dir.c_str(), F_OK) != 0) {
        cerr << "Config directory not found: " << config_dir << endl;
        cout << "Creating config directory..." << endl;
        mkdir(config_dir.c_str(), 0755);
    }

    if (access(plugins_dir.c_str(), F_OK) != 0) {
        cout << "Creating plugins directory..." << endl;
        mkdir(plugins_dir.c_str(), 0755);
    }

    // Load configuration and plugins
    load_config();
    load_plugins();

    // Main command loop
    while (true) {
        string prompt = generate_prompt();

        // Read user input
        char *input = readline(prompt.c_str());

        if (!input) break; // Exit on EOF

        if (*input) add_history(input);

        string cmd(input);
        free(input);

        vector<string> args = tokenize(cmd);
        execute_command(args);
    }

    // Clean up
    if (L) lua_close(L);

    return 0;
}