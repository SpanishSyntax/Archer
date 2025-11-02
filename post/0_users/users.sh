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

get_users() {
    local -n choice="$1"
    local show_sudo="$2"
    local users=($(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd))
    local menu_items=()
    local max_user_len=0

    userlist=""
    local counter=1

    for user in "${users[@]}"; do
        if id "$user" | grep -q 'wheel'; then
            userlist+="$counter. $user has sudo: yes\n"
        else
            userlist+="$counter. $user has sudo: no\n"
        fi

        ((counter++))
    done

    eval "$choice=\"$userlist\""
}

pick_user() {
    local -n user_var="$1"
    local title="$2"
    local description="$3"

    local users_list=()
    users_list=($(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd))
    users_list+=("Exit")

    while true; do
        menu_prompt users_menu_choice "$title" "$description" "${users_list[@]}"
        case $users_menu_choice in
            e)  exit;;
            *)  local USER="${users_list[$((users_menu_choice))]}";break
                ;;
        esac
    done
    user_var="$USER"
}

user_password_prompt () {
    local user="$1"
    local pass="$2"
    ensure_same_pass "$user" user_password && continue_script 2 "Password set!" "Password has been set.\n\nUser: '$user' \nPassword: ${user_password:0:1}*******${user_password: -1}"
    eval "$pass='$user_password'"
}

change_admin_privs() {
    local username="$1"
    local title="Should $username be sudo?"
    local description="Please determine if user $username should have admin privileges or not."
    local options=(\
        "No, dont give admin privileges to $username." \
        "Yes, give $username admin privileges."
    )

    while true; do
        menu_prompt wheel_menu "$title" "$description" "${options[@]}"
        case $wheel_menu in
            0)  sudo_access="n";break;;
            1)  sudo_access="y";break;;
            *)  continue_script 2 "Option not valid" "That is not an option, retry.";;
        esac
    done

    if [[ "$sudo_access" == "y" ]]; then
        usermod -aG wheel "$username" && continue_script 2 "$username is now admin" "User $username now is an admin (wheel)."
    else
        continue_script 2 "User not wheel" "User $username now isn't an admin (wheel)."
    fi
}

create_user() {
    get_users userlist
    input_text\
        username\
        "New user"\
        "Menu for creating a new user.\n\n$userlist"\
        "Enter the username for the new user: "

    local prohibited_usernames=("root" "admin" "test" "user" "guest")
    local username_pattern='^[a-zA-Z0-9._-]+$'
    local min_length=3
    local max_length=32

    while true; do
        if [ -z "${username}" ]; then
            continue_script 2 "Empty username" 'Sorry, you need to enter a username.'
        elif [[ " ${prohibited_usernames[*]} " =~ " ${username} " ]]; then
            continue_script 2 "Prohibited username" 'Sorry, this username is prohibited. Please choose a different username.'
        elif [[ ! "${username}" =~ ${username_pattern} ]]; then
            continue_script 2 "Invalid characters" 'Sorry, the username can only contain letters, numbers, dots, underscores, or dashes.'
        elif (( ${#username} < min_length )); then
            continue_script 2 "Username too short" "Sorry, the username must be at least ${min_length} characters long."
        elif (( ${#username} > max_length )); then
            continue_script 2 "Username too long" "Sorry, the username must be no more than ${max_length} characters long."
        else
            break
        fi

        input_text\
            username\
            "New user"\
            "Menu for creating a new user.\n\n$userlist"\
            "Enter the username for the new user: "
    done
    fullname="$(tr '[:lower:]' '[:upper:]' <<< "${username:0:1}")${username:1}"
    useradd -c "$fullname" -m "$username"
    user_password_prompt "$fullname" user_password

    echo "$username:$user_password" | chpasswd
    
    change_admin_privs "$username"
}

modify_user() {
    
    pick_user \
        username \
        "Menu for editing a user." \
        "Pick the username of the user to edit: "

    fullname="$(tr '[:lower:]' '[:upper:]' <<< "${username:0:1}")${username:1}"
    
    local title="What do you want to do to $username"
    local description="Please determine if you want to change password for $username or if you want to change the admin privileges of $username."
    local options=(\
        "Change password" \
        "Change admin privileges" \
        "Back"
    )

    while true; do
        menu_prompt wheel_menu "$title" "$description" "${options[@]}"
        case $wheel_menu in
            0)  user_password_prompt "$fullname" user_password
                echo "$username:$user_password" | chpasswd
                break;;
            1)  change_admin_privs "$username";break;;
            b)  break;;
            *)  continue_script 2 "Option not valid" "That is not an option, retry.";;
        esac
    done
}

delete_user() {

    pick_user \
        username \
        "Menu for deleting a user." \
        "This will DELETE THEIR FILES! Pick the username of the user to delete: "
    
    local max_user_len=0
    local max_admin_len=3
    local menu_items=()

    if id "$username" &>/dev/null; then
        if [ -e "/var/spool/mail/$username" ]; then
            rm "/var/spool/mail/$username"
        fi
        userdel -r "$username" && continue_script 2 "$username deleted" "User $username and their files deleted."
    else
        continue_script 2 "User doesn't exist" "User $username does not exist."
    fi
}

list_users() {
    get_users userlist
    local max_user_len=0
    local max_admin_len=3
    local menu_items=()

    continue_script 2 "Existing users" "List of Existing Users:\n\n$userlist"
}

users_menu() {
    local title="User Management Setup"
    local description="This section helps you manage users on your system. You can create, modify, delete, or list users, and decide whether they should have admin privileges (sudo)."

    while true; do
        local options=(\
            "Create New User" \
            "Modify Existing User" \
            "Delete User" \
            "List Existing Users" \
            "Back"
        )
        menu_prompt conf_users_menu "$title" "$description" "${options[@]}"
        case $conf_users_menu in
            0)  create_user;;
            1)  modify_user;;
            2)  delete_user;;
            3)  list_users;;
            b)  break;;
            *)  continue_script 2 "Option not valid" "That is not an option, returning to start menu.";exit;;
        esac
    done
}