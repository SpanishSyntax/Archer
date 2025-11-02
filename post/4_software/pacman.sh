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

pacman_menu() {
    local title="Installing extra software from pacman."
    local description="Welcome to the pacman software installation menu. Select the software to install."

    while true; do
        local options=(\
            "Starship                   (A firefox based, pretty and FAST browser.)" \
            "Chezmoi                   (A firefox based, pretty and FAST browser.)" \
            "All apps                      (Install all the above)" \
            "Back"
        )
        menu_prompt flt_choice "$title" "$description" "${options[@]}"
        case $flt_choice in
            0)  install_pacman_starship;;
            1)  install_pacman_chezmoi;;
            2)  install_pacman_zed;;
            3)  install_all_pacmans;;
            b)  break;;
            *)  continue_script 2 "Not a valid choice!" "Invalid choice, please try again.";;
        esac
    done
}

install_all_pacmans () {
    install_pacman_starship
    install_pacman_chezmoi
    install_pacman_zed
    continue_script 2 "Everything" "Everything setup complete!"
}

install_pacman_starship() {
    install_with_pacman starship
}

install_pacman_chezmoi() {
    install_with_pacman chezmoi
}

install_pacman_zed() {
    install_with_pacman zed
}