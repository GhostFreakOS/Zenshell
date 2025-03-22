#include <iostream>
#include <vector>
#include <string>
#include <sstream>
#include <fstream>
#include <unistd.h>
#include <limits.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <dirent.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <dlfcn.h>
#include <unordered_map>
#include <algorithm>
#include <lua.hpp>

#define MAX_INPUT 255

using namespace std;

// Global variables to store active plugins and theme settings

// List of active plugin filenames
vector<string> active_plugins; 

// Key-value pairs for theme settings
unordered_map<string, string> theme_settings;

// Function to get the hostname of the system
string hostname() { 
    char hostbuffer[HOST_NAME_MAX];
    if (gethostname(hostbuffer, sizeof(hostbuffer)) == 0) {
        return std::string(hostbuffer);
    } else {
        // Return empty string on error
        return ""; 
    }
}
// Hostname of the system
string host_name = hostname(); 

/**
 * @brief Loads the configuration file (~/.zencr/config) to initialize plugins and theme settings.
 */

void load_config() {
    ifstream config("~/.zencr/config");
    if (!config) {
        cerr << "Could not open config file." << endl;
        return;
    }

    string line;
    while (getline(config, line)) {
        // Parse lines starting with "plugin:" to load plugins
        if (line.rfind("plugin:", 0) == 0) {
            active_plugins.push_back(line.substr(7));
        }
        // Parse lines starting with "theme:" to load theme settings
        else if (line.rfind("theme:", 0) == 0) {
            size_t delimiter = line.find('=');
            if (delimiter != string::npos) {
                theme_settings[line.substr(6, delimiter - 6)] = line.substr(delimiter + 1);
            }
        }
    }
    config.close();
}

/**
 * @brief Loads Lua plugins from the ~/.zencr/plugins directory.
 *        Only plugins listed in the active_plugins vector are loaded.
 */

void load_plugins() {
    lua_State *L = luaL_newstate();
    luaL_openlibs(L);              

    DIR *dir = opendir("~/.zencr/plugins");
    if (!dir) {
        cerr << "Could not open plugins directory." << endl;
        return;
    }

    struct dirent *entry;
    while ((entry = readdir(dir))) {
        string name = entry->d_name;
        // Check if the file is a Lua script and is listed in active_plugins
        if (name.rfind(".lua") == name.size() - 4) {
            if (find(active_plugins.begin(), active_plugins.end(), name) != active_plugins.end()) {
                string path = "~/.zencr/plugins/" + name;
                // Execute the Lua script
                if (luaL_dofile(L, path.c_str())) {
                    cerr << "Error loading plugin: " << lua_tostring(L, -1) << endl;
                    lua_pop(L, 1); // Remove error message from the stack
                }
            }
        }
    }
    closedir(dir);
    lua_close(L); 
}

/**
 * @brief Applies the theme settings to the shell prompt.
 *        Currently supports setting the prompt colors HEX format.
 */

void apply_theme() {
    if (theme_settings.count("prompt_color")) {
        cout << "\033[" << theme_settings["prompt_color"] << "m";
    }
}

/**
 * @brief Prints the shell prompt with the current user and working directory.
 */

void print_prompt() {
    // Get the current hostname and working directory
    char *user = host_name; 
    char dir[MAX_INPUT];
    getcwd(dir, MAX_INPUT); 
    // Apply theme settings
    apply_theme(); 
    cout << (user ? user : "unknown") << "@" << dir << " -/ $ \033[0m"; // Print the prompt
    fflush(stdout);
}

/**
 * @brief Tokenizes the input string into a vector of arguments.
 * 
 * @param input The input string to tokenize.
 * @return A vector of strings representing the tokens.
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
 * @brief Executes a shell command. Supports built-in commands like `cd` and `exit`.
 *        For other commands, it forks a child process to execute the command.
 * 
 * @param args A vector of strings representing the command and its arguments.
 */

void execute_command(vector<string> args) {
    if (args.empty()) return; // No command to execute

    // Handle the `cd` command
    if (args[0] == "cd") {
        if (args.size() < 2) {
            cerr << "cd: missing argument" << endl;
        } else if (chdir(args[1].c_str()) != 0) {
            perror("cd");
        }
        return;
    }

    // Handle the `exit` command
    if (args[0] == "exit") {
        cout << "Goodbye!" << endl;
        exit(0);
    }

    // Fork a child process to execute other commands
    pid_t pid = fork();
    if (pid == 0) {
        // In the child process
        vector<char*> c_args;
        for (auto &arg : args) c_args.push_back(&arg[0]);
        c_args.push_back(nullptr);
        execvp(c_args[0], c_args.data()); // Execute the command
        perror("exec"); // If execvp fails
        exit(1);
    } else if (pid > 0) {
        // In the parent process, wait for the child to finish
        wait(nullptr);
    } else {
        perror("fork"); // If fork fails
    }
}

/**
 * @brief The main function of the Zen Shell.
 *        Initializes the shell, loads configuration and plugins, and starts the command loop.
 */

int main() {
    cout << "Welcome to Zen Shell!" << endl;

    // Load configuration and plugins
    load_config();
    load_plugins();

    // Main command loop
    while (true) {
        // Read user input
        char *input = readline((host_name + "> ").c_str()); 
        // Exit on EOF
        if (!input) break; 
         // Add input to history if not empty
        if (*input) add_history(input);
         // Tokenize the input
        vector<string> args = tokenize(input);
        // Free the allocated memory for input
        free(input); 
        // Execute the command
        execute_command(args); 
    }

    return 0;
}