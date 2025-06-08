#include "theme.hpp"
#include <regex>
#include <cstdio>

namespace zen {

std::string Theme::hex_to_ansi(const std::string& hex) {
    std::string clean_hex = hex;
    if (hex[0] == '#') {
        clean_hex = hex.substr(1);
    }

    if (clean_hex.length() == 6) {
        int r, g, b;
        sscanf(clean_hex.c_str(), "%02x%02x%02x", &r, &g, &b);
        return "\033[38;2;" + std::to_string(r) + ";" + std::to_string(g) + ";" + std::to_string(b) + "m";
    }

    return "\033[0m";
}

std::string Theme::generate_prompt(const std::string& username,
                                 const std::string& hostname,
                                 const std::string& pwd,
                                 const std::unordered_map<std::string, std::string>& theme_settings) {
    std::string prompt_color = theme_settings.count("prompt_color") ?
                              hex_to_ansi(theme_settings.at("prompt_color")) :
                              "\033[34m";

    std::string reset_color = "\033[0m";
    std::string prompt_format = theme_settings.count("prompt_format") ?
                               theme_settings.at("prompt_format") :
                               "[%u@%h %d]$ ";

    std::string prompt = prompt_format;
    prompt = std::regex_replace(prompt, std::regex("%u"), username);
    prompt = std::regex_replace(prompt, std::regex("%h"), hostname);
    prompt = std::regex_replace(prompt, std::regex("%d"), pwd);

    return prompt_color + prompt + reset_color;
}

} // namespace zen 