#include "shell.hpp"
#include "theme.hpp"
#include <iostream>
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
#include <algorithm>
#include <cstdlib>
#include <csignal>

#define MAX_INPUT 255

namespace zen {

Shell::Shell() : L(nullptr) {
    home_dir = get_home_dir();
    if (home_dir.empty()) {
        throw std::runtime_error("Could not determine home directory");
    }
}

Shell::~Shell() {
    if (L) {
        lua_close(L);
    }
}

std::string Shell::get_home_dir() {
    const char* home = getenv("HOME");
    return home ? std::string(home) : "";
}

std::string Shell::get_hostname() {
    char hostbuffer[HOST_NAME_MAX];
    if (gethostname(hostbuffer, sizeof(hostbuffer)) == 0) {
        return std::string(hostbuffer);
    }
    return "unknown";
}

bool Shell::init_lua() {
    L = luaL_newstate();
    if (!L) return false;
    luaL_openlibs(L);
    return true;
}

void Shell::load_config() {
    if (!L) {
        throw std::runtime_error("Lua environment not initialized");
    }

    std::string config_path = home_dir + "/.zencr/config.lua";
    if (luaL_dofile(L, config_path.c_str())) {
        std::cerr << "Error loading config: " << lua_tostring(L, -1) << std::endl;
        lua_pop(L, 1);
        return;
    }

    // Load plugins
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

    // Load theme settings
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

void Shell::load_plugins() {
    if (!L) {
        throw std::runtime_error("Lua environment not initialized");
    }

    std::string plugins_dir = home_dir + "/.zencr/plugins";
    DIR* dir = opendir(plugins_dir.c_str());
    if (!dir) {
        std::cerr << "Could not open plugins directory: " << plugins_dir << std::endl;
        return;
    }

    struct dirent* entry;
    while ((entry = readdir(dir))) {
        std::string name = entry->d_name;
        if (name.length() > 4 && name.substr(name.length() - 4) == ".lua") {
            if (std::find(active_plugins.begin(), active_plugins.end(), name) != active_plugins.end()) {
                std::string path = plugins_dir + "/" + name;
                if (luaL_dofile(L, path.c_str())) {
                    std::cerr << "Error loading plugin " << name << ": " << lua_tostring(L, -1) << std::endl;
                    lua_pop(L, 1);
                } else {
                    std::cout << "Loaded plugin: " << name << std::endl;
                }
            }
        }
    }
    closedir(dir);
}

std::vector<std::string> Shell::tokenize(const std::string& input) {
    std::vector<std::string> args;
    std::istringstream stream(input);
    std::string token;
    while (stream >> token) {
        args.push_back(token);
    }
    return args;
}

void Shell::execute_command(const std::vector<std::string>& args) {
    if (args.empty()) return;

    if (args[0] == "cd") {
        if (args.size() < 2) {
            if (chdir(home_dir.c_str()) != 0) {
                perror("cd");
            }
        } else if (chdir(args[1].c_str()) != 0) {
            perror("cd");
        }
        return;
    }

    if (args[0] == "exit" || args[0] == "quit") {
        std::cout << "Goodbye!" << std::endl;
        exit(0);
    }

    if (L) {
        lua_getglobal(L, "execute_command");
        if (lua_isfunction(L, -1)) {
            lua_newtable(L);
            for (size_t i = 0; i < args.size(); i++) {
                lua_pushstring(L, args[i].c_str());
                lua_rawseti(L, -2, i+1);
            }

            if (lua_pcall(L, 1, 1, 0) != 0) {
                std::cerr << "Error executing Lua command handler: " << lua_tostring(L, -1) << std::endl;
                lua_pop(L, 1);
            } else if (lua_isboolean(L, -1) && lua_toboolean(L, -1)) {
                lua_pop(L, 1);
                return;
            }
            lua_pop(L, 1);
        } else {
            lua_pop(L, 1);
        }
    }

    pid_t pid = fork();
    if (pid == 0) {
        std::vector<char*> c_args;
        for (const auto& arg : args) {
            c_args.push_back(const_cast<char*>(arg.c_str()));
        }
        c_args.push_back(nullptr);

        execvp(c_args[0], c_args.data());
        perror("exec");
        exit(1);
    } else if (pid > 0) {
        int status;
        waitpid(pid, &status, 0);
    } else {
        perror("fork");
    }
}

void Shell::handle_sigint(int sig) {
    std::cout << "\nUse the 'exit' command to quit the shell." << std::endl;
}

void Shell::run() {
    std::cout << "Welcome to Zen Shell!" << std::endl;
    
    signal(SIGINT, handle_sigint);

    if (!init_lua()) {
        throw std::runtime_error("Failed to initialize Lua environment");
    }

    std::string config_dir = home_dir + "/.zencr";
    std::string plugins_dir = config_dir + "/plugins";

    if (access(config_dir.c_str(), F_OK) != 0) {
        std::cerr << "Config directory not found: " << config_dir << std::endl;
        std::cout << "Creating config directory..." << std::endl;
        mkdir(config_dir.c_str(), 0755);
    }

    if (access(plugins_dir.c_str(), F_OK) != 0) {
        std::cout << "Creating plugins directory..." << std::endl;
        mkdir(plugins_dir.c_str(), 0755);
    }

    load_config();
    load_plugins();

    while (true) {
        std::string username = getenv("USER") ? getenv("USER") : "unknown";
        std::string hostname = get_hostname();
        char dir[MAX_INPUT];
        getcwd(dir, MAX_INPUT);
        std::string pwd(dir);
        if (pwd.find(home_dir) == 0) {
            pwd = "~" + pwd.substr(home_dir.length());
        }

        std::string prompt = Theme::generate_prompt(username, hostname, pwd, theme_settings);
        char* input = readline(prompt.c_str());

        if (!input) break;

        if (*input) add_history(input);

        std::string cmd(input);
        free(input);

        std::vector<std::string> args = tokenize(cmd);
        execute_command(args);
    }
}

} // namespace zen 