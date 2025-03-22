#include <iostream>
#include <vector>
#include <string>
#include <sstream>
#include <fstream>
#include <unistd.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <dirent.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <dlfcn.h>

#define MAX_INPUT 1024

using namespace std;

vector<string> active_plugins;

void load_config() {
    ifstream config("~/.zencr/config");
    if (!config) {
        cerr << "Could not open config file." << endl;
        return;
    }
    string line;
    while (getline(config, line)) {
        if (!line.empty()) active_plugins.push_back(line);
    }
    config.close();
}

void print_prompt() {
    char *user = getenv("USER");
    char dir[MAX_INPUT];
    getcwd(dir, MAX_INPUT);
    cout << "\033[1;34m" << (user ? user : "unknown") << "@" << dir << " -/\033[0m $ ";
    fflush(stdout);
}

vector<string> tokenize(const string &input) {
    vector<string> args;
    istringstream stream(input);
    string token;
    while (stream >> token) {
        args.push_back(token);
    }
    return args;
}

void execute_command(vector<string> args) {
    if (args.empty()) return;
    
    if (args[0] == "cd") {
        if (args.size() < 2) {
            cerr << "cd: missing argument" << endl;
        } else if (chdir(args[1].c_str()) != 0) {
            perror("cd");
        }
        return;
    }
    
    if (args[0] == "exit") {
        cout << "Goodbye!" << endl;
        exit(0);
    }
    
    pid_t pid = fork();
    if (pid == 0) {
        vector<char*> c_args;
        for (auto &arg : args) c_args.push_back(&arg[0]);
        c_args.push_back(nullptr);
        execvp(c_args[0], c_args.data());
        perror("exec");
        exit(1);
    } else if (pid > 0) {
        wait(nullptr);
    } else {
        perror("fork");
    }
}

void load_plugins() {
    DIR *dir = opendir("~/.zencr/plugins");
    if (!dir) return;
    
    struct dirent *entry;
    while ((entry = readdir(dir))) {
        if (strstr(entry->d_name, ".so")) {
            string plugin_name(entry->d_name);
            if (find(active_plugins.begin(), active_plugins.end(), plugin_name) != active_plugins.end()) {
                string plugin_path = string("~/.zencr/plugins/") + entry->d_name;
                void *handle = dlopen(plugin_path.c_str(), RTLD_LAZY);
                if (!handle) {
                    cerr << "Error loading plugin: " << dlerror() << endl;
                }
            }
        }
    }
    closedir(dir);
}

int main() {
    cout << "Welcome to Zen Shell!" << endl;
    load_config();
    load_plugins();
    
    while (true) {
        char *input = readline("Zen> ");
        if (!input) break;
        if (*input) add_history(input);
        vector<string> args = tokenize(input);
        free(input);
        execute_command(args);
    }
    return 0;
}
