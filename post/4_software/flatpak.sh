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

flatpak_menu() {
    install_pacman_packages flatpak

    local title="Installing extra software from Flatpak."
    local description="Welcome to the flatpak software installation menu. Select the software to install."

    while true; do
        local options=(\
            "Zen Browser                   (A firefox based, pretty and FAST browser.)" \
            "Zed Code Editor               (A fast code editor.)" \
            "Visual Studio Code            (classic code editor)" \
            "Spotify                       (Spotify client)" \
            "Discord                       (Discord client)" \
            "Gimp                          (Photoshop)"  \
            "Inkscape                      (Illustrator)" \
            "Blender                       (3D modelling)" \
            "Rnote                         (Whiteboard)" \
            "Kden Live                     (Video editor)" \
            "Steam                         (Game manager)" \
            "All apps                      (Install all the above)" \
            "Back"
        )
        menu_prompt flt_choice "$title" "$description" "${options[@]}"
        case $flt_choice in
            0)  install_flatpak_zen;;
            1)  install_flatpak_zed;;
            2)  install_flatpak_vscode;;
            3)  install_flatpak_spotify;;
            4)  install_flatpak_discord;;
            5)  install_flatpak_gimp;;
            6)  install_flatpak_inkscape;;
            7)  install_flatpak_blender;;
            8)  install_flatpak_rnote;;
            9)  install_flatpak_kden_live;;
            10)  install_flatpak_steam;;
            11)  install_all_flatpaks;;
            b)  break;;
            *)  continue_script 2 "Not a valid choice!" "Invalid choice, please try again.";;
        esac
    done
}

install_with_flatpak() {
    local app="$1"
    local app_id="$2"

    check_flatpak_package "$app" "$app_id"
}

check_flatpak_package() {
    local app="$1"
    local app_id="$2"

    if flatpak list --app | grep -qw "$app_id"; then
        continue_script 2 "$app already installed" "$app is already installed."
    else
        install_flatpak_app "$app" "$app_id"
    fi
}

install_flatpak_app() {
    local app="$1"
    local app_id="$2"

    local commands_to_run=()
    commands_to_run+=("flatpak install --assumeyes --noninteractive $app_id")
    live_command_output "" "" "Installing $app" "${commands_to_run[@]}"
}

install_all_flatpaks () {
    install_flatpak_zen
    install_flatpak_zed
    install_flatpak_vscode
    install_flatpak_spotify
    install_flatpak_gimp
    install_flatpak_inkscape
    install_flatpak_blender
    install_flatpak_rnote
    install_flatpak_kden_live
    install_flatpak_steam
    continue_script 2 "Everything" "Everything setup complete!"
}

install_flatpak_zen() {
    local app="Zen"
    local app_id="app.zen_browser.zen"
    install_with_flatpak "$app" "$app_id"
}

install_flatpak_zed () {
    local app="Zed editor"
    local app_id="dev.zed.Zed"
    install_with_flatpak "$app" "$app_id"
}

install_flatpak_vscode () {
    local app="Visual Studio Code"
    local app_id="com.visualstudio.code"
    install_with_flatpak "$app" "$app_id"
}

install_flatpak_spotify () {
    local app="Spotify"
    local app_id="com.spotify.Client"
    install_with_flatpak "$app" "$app_id"
}

install_flatpak_discord () {
    local app="Discord"
    local app_id="com.discordapp.Discord"
    install_with_flatpak "$app" "$app_id"
}

install_flatpak_gimp () {
    local app="Gimp"
    local app_id="org.gimp.GIMP"
    install_with_flatpak "$app" "$app_id"
}

install_flatpak_inkscape () {
    local app="Inkscape"
    local app_id="org.inkscape.Inkscape"
    install_with_flatpak "$app" "$app_id"
}

install_flatpak_blender () {
    local app="Blender"
    local app_id="org.blender.Blender"
    install_with_flatpak "$app" "$app_id"
}

install_flatpak_rnote () {
    local app="Rnote"
    local app_id="com.github.flxzt.rnote"
    install_with_flatpak "$app" "$app_id"
}

install_flatpak_kden_live () {
    local app="Kden Live"
    local app_id="org.kde.kdenlive"
    install_with_flatpak "$app" "$app_id"
}

install_flatpak_steam () {
    local app="Steam"
    local app_id="com.valvesoftware.Steam"
    install_with_flatpak "$app" "$app_id"
}
