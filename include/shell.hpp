#pragma once

#include <string>
#include <vector>
#include <unordered_map>
#include <lua.hpp>

namespace zen {

class Shell {
public:
    Shell();
    ~Shell();

    void run();
    static std::string get_home_dir();
    static std::string get_hostname();
    static std::vector<std::string> tokenize(const std::string& input);

private:
    bool init_lua();
    void load_config();
    void load_plugins();
    void execute_command(const std::vector<std::string>& args);
    static void handle_sigint(int sig);

    std::vector<std::string> active_plugins;
    std::unordered_map<std::string, std::string> theme_settings;
    std::string home_dir;
    lua_State* L;
};

} // namespace zen 