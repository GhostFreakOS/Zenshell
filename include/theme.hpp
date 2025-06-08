#pragma once

#include <string>
#include <unordered_map>

namespace zen {

class Theme {
public:
    static std::string hex_to_ansi(const std::string& hex);
    static std::string generate_prompt(const std::string& username, 
                                     const std::string& hostname,
                                     const std::string& pwd,
                                     const std::unordered_map<std::string, std::string>& theme_settings);
};

} // namespace zen 