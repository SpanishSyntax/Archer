#!/bin/bash

# Copyright (C) 2021-2024 Thien Tran, Tommaso Chiti
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

source ./commons.sh
source ./post/4_software/pacman_installer.sh

mise_menu () {
    install_pacman_packages mise

    local title="Installing extra software from mise."
    local description="This script helps you easily install and manage tools using the mise version manager."
    
    while true; do
        local options=(\
            'Python             (Installs Python and its dependencies, including pip and virtualenv)' \
            'Node               (Installs Node.js, npm, and related JavaScript development tools)' \
            'Java               (Installs the Java Development Kit (JDK) for Java development)' \
            'Rust               (Installs Rust programming language and Cargo package manager)' \
            'PHP                (Installs PHP and common PHP development tools)' \
            'Make               (Installs GCC, Make, and other necessary tools for C development)' \
            'CMake              (Installs CMake, a tool for managing build processes in C/C++)' \
            'Ninja              (Installs Ninja, a fast build system for compiling projects)' \
            '.NET               (Installs .NET SDK for cross-platform application development)' \
            'Neovim             (Installs Neovim, a modern, extensible text editor for developers)' \
            'Glow               (Installs Glow, a markdown reader)' \
            'Install all        (Install all the above)' \
            'Back' \
        )

        menu_prompt virt_menu_choice "$title" "$description" "${options[@]}"
        case $virt_menu_choice in
            0)  configure_python;;
            1)  configure_node;;
            2)  configure_java;;
            3)  configure_rust;;
            4)  configure_php;;
            5)  configure_make;;
            6)  configure_cmake;;
            7)  configure_ninja;;
            8)  configure_dotnet;;
            9)  configure_neovim;;
            10) configure_glow;;
            11) install_all_mise;;
            b)  break;;
            *)  continue_script 2 "Not a valid choice!" "Invalid choice, please try again.";;
        esac
    done
}

install_all_mise() {
    configure_python
    configure_node
    configure_java
    configure_rust
    configure_php
    configure_make
    configure_cmake
    configure_ninja
    configure_dotnet
    configure_neovim
    configure_chezmoi
    configure_starship
    configure_glow
}

configure_python() {
    local item="python"
    local version="3.12.3"
    mise use -g "$item"@"$version"
}

configure_php() {
    local item="php"
    local version="latest"
    mise use -g "$item"@"$version"
}

configure_node() {
    local item="nodejs"
    local version="latest"
    mise use -g "$item"@"$version"
    mise use -g "pnpm"@"$version"
}

configure_deno() {
    local item="deno"
    local version="latest"
    mise use -g "$item"@"$version"
}

configure_node() {
    local item="nodejs"
    local version="latest"
    mise use -g "$item"@"$version"
}

configure_java() {
    local item="java"
    local version="openjdk"
    mise use -g "$item"@"$version"
}

configure_rust() {
    local item="rust"
    local version="latest"
    mise use -g "$item"@"$version"
}

configure_make() {
    local item="make"
    local version="latest"
    mise use -g "$item"@"$version"
}

configure_cmake() {
    local item="cmake"
    local version="latest"
    mise use -g "$item"@"$version"
}

configure_ninja() {
    local item="ninja"
    local version="latest"
    mise use -g "$item"@"$version"
}

configure_dotnet() {
    local item="dotnet"
    local version="latest"
    mise use -g "$item"@"$version"
}

configure_neovim() {
    local item="neovim"
    local version="latest"
    mise use -g "$item"@"$version"
}

configure_glow() {
    local item="glow"
    local version="latest"
    mise use -g "$item"@"$version"
}
