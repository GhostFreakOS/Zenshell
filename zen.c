#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <fcntl.h>
#include <dirent.h>
#include <readline/readline.h>
#include <readline/history.h>

#define MAX_INPUT 1024
#define MAX_ARGS 64
#define PLUGIN_DIR "~/.zencr/plugins"

// Function to print prompt with colors and formatting
void print_prompt() {
    char *user = getenv("USER");
    char dir[MAX_INPUT];
    getcwd(dir, MAX_INPUT);
    printf("\033[1;32m%s\033[1;34m@\033[1;36m%s\033[1;33m$ \033[0m", user ? user : "unknown", dir);
}

// Tokenize input into arguments
int tokenize(char *input, char *args[]) {
    int argc = 0;
    char *token = strtok(input, " \n");
    while (token && argc < MAX_ARGS - 1) {
        args[argc++] = token;
        token = strtok(NULL, " \n");
    }
    args[argc] = NULL;
    return argc;
}

// Built-in: cd
int builtin_cd(char *args[]) {
    if (!args[1]) {
        fprintf(stderr, "cd: missing argument\n");
        return 1;
    }
    if (chdir(args[1]) != 0) {
        perror("cd");
        return 1;
    }
    return 0;
}

// Load plugins from ~/.zencr/plugins
void load_plugins() {
    DIR *d;
    struct dirent *dir;
    d = opendir(PLUGIN_DIR);
    if (d) {
        while ((dir = readdir(d)) != NULL) {
            if (strstr(dir->d_name, ".so")) {
                char plugin_path[MAX_INPUT];
                snprintf(plugin_path, sizeof(plugin_path), "%s/%s", PLUGIN_DIR, dir->d_name);
                void *handle = dlopen(plugin_path, RTLD_LAZY);
                if (!handle) {
                    fprintf(stderr, "Error loading plugin %s: %s\n", dir->d_name, dlerror());
                }
            }
        }
        closedir(d);
    }
}

// Execute command with redirection and piping support
void execute(char *input) {
    char *args[MAX_ARGS];
    char *redir_in = NULL, *redir_out = NULL;
    char *pipe_cmd = strchr(input, '|');

    if (pipe_cmd) {
        *pipe_cmd = 0;
        pipe_cmd++;
        
        int pipefd[2];
        pipe(pipefd);
        pid_t pid1 = fork();
        
        if (pid1 == 0) {
            close(pipefd[0]);
            dup2(pipefd[1], STDOUT_FILENO);
            close(pipefd[1]);
            tokenize(input, args);
            execvp(args[0], args);
            perror("exec");
            exit(1);
        }
        
        pid_t pid2 = fork();
        if (pid2 == 0) {
            close(pipefd[1]);
            dup2(pipefd[0], STDIN_FILENO);
            close(pipefd[0]);
            tokenize(pipe_cmd, args);
            execvp(args[0], args);
            perror("exec");
            exit(1);
        }
        
        close(pipefd[0]);
        close(pipefd[1]);
        waitpid(pid1, NULL, 0);
        waitpid(pid2, NULL, 0);
        return;
    }
    
    int argc = tokenize(input, args);
    if (!args[0]) return;
    
    if (strcmp(args[0], "cd") == 0) {
        builtin_cd(args);
        return;
    }
    if (strcmp(args[0], "exit") == 0) {
        printf("Goodbye!\n");
        exit(0);
    }
    
    pid_t pid = fork();
    if (pid == 0) {
        execvp(args[0], args);
        fprintf(stderr, "\033[1;31mError: '%s' not found\033[0m\n", args[0]);
        exit(1);
    } else if (pid > 0) {
        wait(NULL);
    } else {
        perror("fork");
    }
}

int main() {
    char *input;
    printf("Welcome to Zen - A Tranquil Shell!\n");
    load_plugins();
    using_history();
    
    while (1) {
        print_prompt();
        input = readline("");
        if (!input) break;
        if (*input) add_history(input);
        
        if (strlen(input) > 1) {
            execute(input);
        }
        free(input);
    }
    return 0;
}
