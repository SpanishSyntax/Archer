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
source ./post/0_users/users.sh
source ./post/4_software/pacman_installer.sh

aur_menu() {
    local title="Installing extra software from the AUR"
    local description="Welcome to the AUR software installation menu. Select the software to install."

    while true; do
        local options=(\
            "Install Paru"\
            "Install Rofi power menu"\
            "Back"
        )
        menu_prompt aur_choice "$title" "$description" "${options[@]}"
        case $aur_choice in
            0)  configure_paru;;
            1)  configure_aur_rofi_power_menu;;
            b)  break;;
            *)  continue_script 2 "Not a valid choice!" "Invalid choice, please try again.";;
        esac
    done
}

install_aur_package () {
    local url="$1"
    local package=$(basename "$url" .git)

    if ! check_pacman_package "$package"; then
        install_without_paru "$url"
    fi
}

install_without_paru() {
    local url="$1"
    local bui_user="$USER_WITH_ROOT"
    local package_name=$(basename "$url" .git)
    local build_path="/usr/local/src/aur-builds/$package_name"

    if [[ ! -d "$build_path" ]]; then
        local commands_to_run=()
        commands_to_run+=("mkdir -p $build_path && git clone $url $build_path && chown -R $bui_user:$bui_user $build_path")
        live_command_output "" "" "Cloning $package_name" "${commands_to_run[@]}"
    fi

    if ! ls $build_path/*.pkg.tar.zst &>/dev/null; then
        scroll_window_output return_value "Viewing PKGBUILD for $package_name" "$build_path/PKGBUILD"
        if [ $return_value -eq 3 ]; then
            continue_script 2 "You decided to cancel install" "You did not agree with the PKGBUILD commands and setup. Exiting."
            exit 1
        fi
        live_command_output "makepkg" "$bui_user" "Building and installing $package_name" "cd $build_path && makepkg -sric --noconfirm"
    fi

    continue_script 2 "$package_name installed" "$package_name install complete!"
}

configure_paru() {
    install_aur_package "https://aur.archlinux.org/paru.git"
}

configure_aur_rofi_power_menu() {
    install_aur_package "https://aur.archlinux.org/rofi-power-menu.git"
}
