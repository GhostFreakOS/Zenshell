#include "shell.hpp"
#include <iostream>

int main() {
    try {
        zen::Shell shell;
        shell.run();
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    return 0;
} 