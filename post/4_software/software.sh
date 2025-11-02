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
source ./post/4_software/pacman.sh
source ./post/4_software/aur.sh
source ./post/4_software/flatpak.sh
source ./post/4_software/mise.sh
source ./post/4_software/asdf.sh

software_menu() {
    local title="Install extra software"
    local description="Welcome to the extra software installation menu. Select the software tool to install."

    while true; do
        local options=(\
            "Install from Pacman"\
            "Install from AUR"\
            "Install from Flatpak"\
            "Install from MISE"\
            "Install from ASDF"\
            "Back"
        )
        menu_prompt source_choice "$title" "$description" "${options[@]}"
        case $source_choice in
            0)  pacman_menu;;
            1)  aur_menu;;
            2)  flatpak_menu;;
            3)  mise_menu;;
            4)  asdf_menu;;
            b)  break;;
            *)  continue_script 2 "Not a valid choice!" "Invalid choice, please try again.";;
        esac
    done
}

check_command_exists() {
    local package="$1"

    if command -v "$package" >/dev/null; then
        return 0
    else
        return 1
    fi
}
